require 'socket'
require_relative 'client'
require_relative 'controller'

class SocketServer
  PORT = '3336'.freeze

  attr_reader :controller

  def start
    @server = TCPServer.new(PORT)
    @controller = Controller.new
  end

  def stop
    @server.close if @server
  end

  def accept_new_client
    client_socket = @server.accept_nonblock
    client = Client.new(client_socket)
    controller.add_client(client)
  rescue IO::WaitReadable, Errno::EINTR
    puts 'No client to accept'
  end
end
