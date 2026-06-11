require 'socket'
require_relative 'client'
require_relative 'room'
require_relative 'player'
require_relative 'user'

class SocketServer
  PORT = '3336'.freeze

  attr_reader :pending_clients, :rooms

  def initialize
    @pending_clients = []
    @rooms = []
  end

  def start
    @server = TCPServer.new(PORT)
  end

  def stop
    @server.close if @server
  end

  def accept_new_client
    client_socket = @server.accept_nonblock
    client = Client.new(client_socket)
    client.puts_socket('Welcome!')
    pending_clients.push(client)
  rescue IO::WaitReadable, Errno::EINTR
    # puts 'No client to accept'
  end

  def open_room_ids
    rooms.map(&:id)
  end

  def room_by_id(room_id)
    rooms[rooms.index { |room| room.id == room_id }]
  end

  def handle_pending_clients
    ready_clients = pending_clients.select { |client| client.ready?(open_room_ids) }

    # delete ready clients from pending clients
    pending_clients.reject! { |client| client.ready?(open_room_ids) }

    return if ready_clients.nil?

    # move all ready clients to a game
    handle_pending_hosts(ready_clients.select(&:host?))
    handle_pending_visitors(ready_clients.reject(&:host?))
  end

  def run_game_if_possible
    if controller.started?
      controller.run_round
    elsif controller.ready?
      controller.start_game
    end
  end

  private

  # hosts get their own room
  def handle_pending_hosts(host_clients)
    host_clients.each do |client|
      user = User.new(client, Player.new(client.name))
      rooms.push(Room.new(user))
    end
  end

  # visitors join existing room
  def handle_pending_visitors(visitor_clients)
    visitor_clients.each do |client|
      user = User.new(client, Player.new(client.name))
      room_by_id(client.desired_room_id).add_user(user)
    end
  end
end
