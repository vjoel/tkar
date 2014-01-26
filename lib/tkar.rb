require 'enumerator'

module Tkar
  class Error < StandardError; end
  module Recoverable; end
  
  RADIANS_TO_DEGREES = 180.0 / Math::PI
  DEGREES_TO_RADIANS = Math::PI / 180.0

  require 'tkar/window'
  require 'tkar/stream'

  def self.run(argv, opts)
    verbose = opts["v"]
    title = argv.empty? ?  "stdin" : argv.join(":")
    root = TkRoot.new { title "Tkar @ #{title}"; iconname "Tkar" }
    root.resizable true, true
    window = Window.new(root, opts)
    canvas = window.canvas

    thread = Thread.new do
      movie = false
      if movie
        win_id = root.winfo_id
        pid = Process.pid
      end
      
      persist = opts["persist"]
      
      f = MessageStream.for(argv, opts)
      window.def_message_out do |msg|
        begin
          f.put_msg msg if f
          $stderr.puts msg if verbose
        rescue MessageStream::StreamClosed
        rescue Errno::ECONNABORTED, Errno::ECONNRESET
          raise unless persist
        end
      end

      cmd = args = nil
    
      update_count = 0
      start_time = Time.now
      
      j = 0
      begin
        loop do
          cmd, *args = f.get_cmd
          break if cmd == "done"
          exit if cmd == "exit"
          if cmd == "update"
            f.put_msg "update" ## optional?
            update_count += 1
            if verbose and update_count % 100 == 0
              rate = update_count / (Time.now - start_time)
              $stderr.puts "update rate: %10.2f updates per second" % rate
              update_count = 0
              start_time = Time.now
            end
          end
          r = canvas.send(cmd, *args)
          # f.put_msg return_value if return_value ?
          
          if movie and cmd == "update"
            # add a frame to the movie
            mcmd =
              "import -window #{win_id} \"tmp/#{pid}_frame_%05d.miff\"" % j
            j += 1
            rslt = system(mcmd)
            unless rslt
              puts $?
              exit
            end
          end
        end
      rescue MessageStream::StreamClosed
        f.put_msg "stream closed"
        exit unless persist
        canvas.update
      rescue Recoverable => ex
        f.put_msg ex
        retry
      rescue Errno::ECONNABORTED, Errno::ECONNRESET
        raise unless persist
      rescue => ex
        begin
            f.put_msg ex
            f.put_msg "exiting"
        rescue Errno::ECONNABORTED, Errno::ECONNRESET
        end
        $stderr.puts "#{ex.class}: #{ex.message}", ex.backtrace.join("\n  ")
        raise unless persist
      end
    end

#     if /mswin32/ =~ RUBY_PLATFORM
#       3.times do
#         timer = TkTimer.new(1) do
#           3.times {thread.run}
#         end
#
#         timer.start
#       end
#     end

    Tk.mainloop
  end
end
