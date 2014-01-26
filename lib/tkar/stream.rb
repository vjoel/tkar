require 'socket'
require 'thread'

module Tkar
  module MessageStream
    # Get a bidirectional stream for sending and receiving Tkar
    # protocol messages in either binary or ascii format.
    def self.for(argv, opts = {})
      binary, client = opts["b"], opts["c"]
      (binary ? Binary : Ascii).new(opts, *get_fds(argv, client))
    end

    def self.get_fds argv, client
      case argv.size
      when 0
        [$stdin, $stdout]
      when 1
        case argv[0]
        when /^\d+$/
          if client
            [TCPSocket.new("127.0.0.1", Integer(argv[0]))]
          else
            server = TCPServer.new("127.0.0.1", Integer(argv[0]))
            flag = Socket.do_not_reverse_lookup
            Socket.do_not_reverse_lookup = false
            port = server.addr[1]
            Socket.do_not_reverse_lookup = flag
            puts "listening on port #{port}"
            [server.accept]
          end
        else
          if client
            [UNIXSocket.new(argv[0])]
          else
            [UNIXServer.new(argv[0]).accept]
          end
        end
      when 2
        case argv[1]
        when /^\d+$/
          if client
            [TCPSocket.new(argv[0], Integer(argv[1]))]
          else
            [TCPServer.new(argv[0], Integer(argv[1])).accept]
          end
        else
          raise "Bad arguments--second arg must be port: #{argv.inspect}"
        end
      else
        raise "Too many arguments: #{argv.inspect}"
      end
    end
    
    class StreamClosed < IOError; end

    class Base
      def initialize(opts, fd_in, fd_out = fd_in)
        @flip = opts["flip"]
        @radians = opts["radians"]
        @verbose = opts["v"]

        @fd_in, @fd_out = fd_in, fd_out
        @fd_in_stack = []
        @fd_out_mutex = Mutex.new
      end
    end

    # Translate ascii command text to ruby method calls.
    class Ascii < Base
      NORMALIZE = {}

      %w{ a>dd d>el|delete m>ove>to r>ot|rotate p>ar>am s>h>ape u>p>date title
          background|bg height width zoom_to|zoom view_at|view view_id wait
          follow done bound>s load exit delete_all scale>_obj echo window_xy
       }.each do |s|
        alts = s.split("|")
        cmd = alts.first.delete(">")
        alts.each do |alt|
          parts = alt.split(">")
          parts.inject("") do |prefix, part|
            prefix << part
            NORMALIZE[prefix] = cmd
            prefix
          end
        end
      end

      def conv_param(s)
         s.slice!(/\.0+$/) # so that floats can be used for colors
        (Integer(s) rescue Float(s)) rescue s
      end
      
      def flip_Float(s)
        @flip ? -Float(s) : Float(s)
      end

      def conv_angle(s)
        r = flip_Float(s)
        @radians ? r : r * DEGREES_TO_RADIANS
      end

      ARG_CONVERSION = {
        "add"         => [nil, :Integer, nil, :Integer,
                          :Float, :flip_Float, :conv_angle, :conv_param],
        "del"         => [:Integer],
        "moveto"      => [:Integer, :Float, :flip_Float],
        "rot"         => [:Integer, :conv_angle],
        "param"       => [:Integer, :Integer, :conv_param], ## see below
        "shape"       => [nil, nil],
        "update"      => [],
        "title"       => [], ## see below
        "background"  => [:conv_param],
        "height"      => [:Float],
        "width"       => [:Float],
        "zoom_to"     => [:Float],
        "view_at"     => [:Float, :flip_Float],
        "view_id"     => [:Integer],
        "wait"        => [:Float],
        "follow"      => [:Integer],
        "done"        => [],
        "bounds"      => [:Float, :flip_Float, :Float, :flip_Float],
        "load"        => [], ## see below
        "exit"        => [],
        "delete_all"  => [],
        "scale_obj"   => [:Integer, :Float, :Float],
        "echo"        => [], ## see below
        "window_xy"   => [:Integer, :Integer],
      }
      
      def get_line
        line = @fd_in.gets
        while line == nil and not @fd_in_stack.empty?
          @fd_in = @fd_in_stack.pop
          line = @fd_in.gets
        end
        if line
          while line =~ /(.*)\\\r?$/ # to allow continuation of long lines
            next_line = @fd_in.gets
            break unless next_line
            line = $1 + next_line
          end
        end
        line
      end
      
      class TryAgain < StandardError; end

      # Returns next command in pipe, in form <tt>[:meth, arg, arg, ...]</tt>.
      def get_cmd
        begin
          cmdline = get_line
          raise StreamClosed, "Session ended" unless cmdline ## ?
        end while cmdline =~ /^\s*(#|$)/
        parse_cmd(cmdline)
      rescue TryAgain
        retry
      rescue SystemCallError => ex
        $stderr.puts ex.class, ex.message
        raise StreamClosed, "Session ended"
      end

      def parse_cmd cmdline
        $stderr.puts cmdline if @verbose
        cmd, *args = cmdline.split
        cmd = NORMALIZE[cmd] || (raise ArgumentError, "Bad command: #{cmd}")
        
        case cmd
        when "param"
          return [cmd, Integer(args.shift), Integer(args.shift),
            conv_param(args.join(" "))]
          ## hacky, and loses multiple spaces
        when "title"
          return [cmd, args.join(" ")]
        when "echo"
          str = args.join(" ")
          ## hacky, and loses multiple spaces
          put_msg(str)
          raise TryAgain # hm...
        when "load"
          filename = args.join(" ")
          ## hacky, and loses multiple spaces
          begin
            new_fd_in = File.open(filename)
          rescue Errno::ENOENT # if not absolute, try local
            raise unless @fd_in_dir
            new_fd_in = File.open(File.join(@fd_in_dir, filename))
          end
          @fd_in_dir ||= File.dirname(new_fd_in.path)
          @fd_in_stack.push(@fd_in)
          @fd_in = new_fd_in
          raise TryAgain # hm...
        end
        
        conv = ARG_CONVERSION[cmd]
        unless conv
          raise "No argument conversion for command #{cmd.inspect}"
        end
        i = -1; last_i = conv.length - 1
        args.map! do |arg|
          i += 1 unless i == last_i # keep using the last conversion thereafter
          (c = conv[i]) ? send(c, arg) : arg
        end
        [cmd, *args]
      end

      def put_msg(msg)
        @fd_out_mutex.synchronize do ## why necessary?
          @fd_out.puts msg
        end
        @fd_out.flush
      rescue Errno::ECONNABORTED
      end
    end

    # Translate binary command data to ruby method calls.
    class Binary < Base
      def get_cmd
        lendata = @fd_in.recv(4)
        raise "Session ended" if lendata.empty?

        len = lendata.unpack("N")
        if len < 4
          raise ArgumentError, "Input too short: #{len}"
        end
        if len > 10000
          raise ArgumentError, "Input too long: #{len}"
        end

        msg = ""
        part = nil
        while (delta = len - msg.length) > 0 and (part = @fd_in.recv(delta))
          if part.length == 0
            raise \
              "Peer closed socket before finishing message --" +
              " received #{msg.length} of #{len} bytes:\n" +
              msg[0..99].unpack("H*")[0] + "..."
          end
          msg << part
        end

        raise StreamClosed, "Session ended" if msg.empty?
        parse_cmd(msg)
      end

      CMD_DATA = {
        1   => ["add",    "Z* N Z* N g3 N*"],
        2   => ["del",    "N"],
        3   => ["moveto", "N g2"],
        4   => ["rot",    "N g"],
        5   => ["param",  "N n N"], ## fix to allow strings
        6   => ["shape",  "Z* Z*"],
        7   => ["update", ""],
        8   => ["title",  "Z*"],
        9   => ["background",     "N"],
        10  => ["height", "g"],
        11  => ["width", "g"],
        12  => ["zoom_to", "g"],
        13  => ["view_at", "g2"],
        14  => ["view_id", "N"],
        15  => ["wait", "g"],
        16  => ["follow", "N"],
        17  => ["done", ""],
        18  => ["bounds", "NNNN"],
        19  => ["load",  "Z*"],
        20  => ["exit", ""],
        21  => ["delete_all", ""],
        22  => ["scale_obj", "N g2"],
        23  => ["echo",  "Z*"],
        24  => ["window_xy", "NN"],
      }

      def parse_cmd msg
        cmd = msg[0..1].unpack("n")
        cmd, fmt = CMD_DATA[cmd]
        [cmd, *msg[2..-1].unpack(fmt)]
      end

      def put_msg(msg)
        @fd_out.puts msg ## assume output ascii for now
        @fd_out.flush
      end
    end
  end
end
