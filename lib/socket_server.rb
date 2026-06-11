require 'socket'
require_relative 'client'
require_relative 'controller'
require_relative 'player'
require_relative 'user'

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

  def pending_clients
    @pending_clients ||= []
  end

  def pending_users
    @pending_users ||= []
  end

  def names_asked
    @names_asked ||= {}
  end

  def accept_new_client
    client_socket = @server.accept_nonblock
    client = Client.new(client_socket)
    client.puts_socket('Welcome!')
    pending_clients.push(client)
  rescue IO::WaitReadable, Errno::EINTR
    # puts 'No client to accept'
  end

  def handle_pending_clients
    pending_clients.each do |client|
      collect_client_name(client)
    end

    pending_users.each do |user|
      names_asked.delete(user.client)
      pending_clients.delete(user.client)
    end
  end

  def run_game_if_possible
    if controller.started?
      controller.run_round
    elsif controller.ready?
      controller.start_game
    end
  end

  private

  def collect_client_name(client)
    client.ask_socket('Enter name') unless names_asked[client]
    names_asked[client] = true

    input = client.read_socket
    return if input.empty?

    validate_player_name(input.chomp.strip, client)
  end

  def validate_player_name(name, client)
    if valid_player_name?(name)
      pending_users.push(User.new(client, Player.new(name)))
    else
      client.puts_socket('Invalid name!')
      names_asked[client] = nil
    end
  end

  def valid_player_name?(name)
    !name.empty?
  end
end
