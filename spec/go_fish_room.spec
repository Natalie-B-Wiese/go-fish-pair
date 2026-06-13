require 'socket'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'
require_relative '../lib/client'
require_relative '../lib/go_fish/go_fish_room'

describe GoFishRoom do
  let!(:server) { SocketServer.new }

  before(:each) do
    server.start
    sleep 0.1 # Ensure server is ready for clients
  end

  after(:each) do
    server.stop
  end

  def question_regex(regex)
    Regexp.new(regex.source + /.*#{Client::INPUT_SYMBOL}/.source)
  end

  def create_and_accept_new_client
    client = MockSocketClient.new
    server.accept_new_client
    client
  end

  def create_user(name)
    real_client = server.pending_clients.shift

    while real_client.nil?
      puts 'server.pending_clients is empty! Trying again...'
      sleep(0.1)
      real_client = server.pending_clients.shift
    end

    User.new(real_client, Player.new(name))
  end

  let(:room_id) { '0123' }
  let(:capacity) { 3 }

  let(:player1_name) { 'Bob' }
  let!(:client1) { create_and_accept_new_client }

  let(:player2_name) { 'Jeff' }
  let!(:client2) { create_and_accept_new_client }

  let(:player3_name) { 'Batman' }
  let!(:client3) { create_and_accept_new_client }

  # room that is full of players and already started
  let!(:room) do
    GoFishRoom.new(create_user(player1_name), capacity: capacity, id: room_id)
  end

  before do
    room.add_user(create_user(player2_name))
    room.add_user(create_user(player3_name))
    room.start_game

    client1.capture_output
    client2.capture_output
    client3.capture_output
  end

  # run_room_if_possible
  describe '#play_round' do
    before do
      room.play_round
    end

    it 'shows all clients whose turn it is' do
      expect(client1.capture_output).to match(/your turn/)
      expect(client2.capture_output).to match(/#{player1_name}'s turn/)
      expect(client3.capture_output).to match(/#{player1_name}'s turn/)
    end
  end
end
