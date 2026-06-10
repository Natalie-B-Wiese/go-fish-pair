require 'socket'

class Client
  attr_reader :socket

  INPUT_SYMBOL = '->'

  def initialize(socket)
    @socket = socket
  end

  def read_socket
    socket.read_nonblock(1000)
  rescue IO::WaitReadable
    ''
  end

  def puts_socket(message)
    socket.puts(message)
  end

  def ask_socket(message)
    puts_socket(message + INPUT_SYMBOL)
    read_socket
  end
end
