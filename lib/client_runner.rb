require 'socket'
require_relative 'client'

socket = TCPSocket.new('localhost', 3336)
while true
  output = ''
  until output != ''
    begin
      sleep(0.1)
      output = socket.read_nonblock(1000).chomp # not gets which blocks
    rescue IO::WaitReadable
    end
  end
  if output.include?(Client::INPUT_SYMBOL)
    print output + ' '
    socket.puts(gets.chomp)
  else
    puts output
  end
end
