# Run server first, then start clients with:
#   tkar -c localhost 9000

require 'socket'

svr = TCPServer.open("localhost", 9000)

stuff = %{
shape box rect50,50,0,0,fc:yellow;rect10,10,2,2,fc:red
add box 3 - 4 10 10 0 ff0000 00ff00
}

@last = nil

clients = []
Thread.new do
  i = 0
  loop do
    s = svr.accept
    s.puts "title Client #{i}", stuff
    s.puts "moveto #{@last}" if @last
    s.puts "update"
    s.flush
    clients << s
    i += 1
  end
end

loop do
  r=select(clients, nil, nil, 1.0); next unless r
  client = r[0][0]
  line = client.gets
  case line
  when /^drag (.*)/ 
    @last = $1
    (clients-[client]).each do |other_client|
      other_client.puts %{
        moveto #{@last}
        update
      }
    end
  when nil
    clients.delete client
  end
end
