require 'socket'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'
require_relative '../lib/client'
require_relative '../lib/go_fish/game'

describe Room do
  let!(:server) { SocketServer.new }

  before(:each) do
    server.start
    sleep 0.1 # Ensure server is ready for clients

    # surpress not implemented errors
    allow_any_instance_of(Room).to receive(:new_game).and_return(Game.new([]))
    allow_any_instance_of(Room).to receive(:run_started_game)
    allow_any_instance_of(Room).to receive(:starting_message).and_return('starting')

    allow_any_instance_of(Game).to receive(:start).and_return(true)
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
  let(:player1_name) { 'Bob' }
  let(:player2_name) { 'Jeff' }
  let(:player3_name) { 'Batman' }
  let(:capacity) { 3 }

  describe '#add_user' do
    let!(:client1) { create_and_accept_new_client }

    let!(:room) do
      Room.new(create_user(player1_name), capacity: capacity, id: room_id)
    end

    context 'with one client' do
      it 'shows room id to newly joined client' do
        expect(client1.capture_output).to match(/#{room_id}/)
      end

      it 'shows remaining players needed to reach capacity' do
        expect(client1.capture_output).to match(/waiting.*#{capacity - room.num_players}/i)
      end

      it 'does not show playing with message' do
        expect(client1.capture_output).to_not match(/playing with/i)
      end
    end

    context 'when more players join' do
      it 'shows room id to new clients' do
        client2 = create_and_accept_new_client
        client2.capture_output
        room.add_user(create_user(player2_name))
        expect(client2.capture_output).to match(/#{room_id}/)

        client3 = create_and_accept_new_client
        room.add_user(create_user(player3_name))
        expect(client3.capture_output).to match(/#{room_id}/)
      end

      it 'shows previous players to new clients' do
        client2 = create_and_accept_new_client
        client2.capture_output
        room.add_user(create_user(player2_name))
        expect(client2.capture_output).to match(/#{player1_name}/)

        client3 = create_and_accept_new_client
        room.add_user(create_user(player3_name))
        expect(client3.capture_output).to match(/#{player1_name}, #{player2_name}/)
      end

      it 'shows new players to previous players' do
        client2 = create_and_accept_new_client
        client2.capture_output
        room.add_user(create_user(player2_name))

        expect(client1.capture_output).to match(/#{player2_name}/)
        client2.capture_output

        client3 = create_and_accept_new_client
        room.add_user(create_user(player3_name))

        expect(client1.capture_output).to match(/#{player3_name}/)
        expect(client2.capture_output).to match(/#{player3_name}/)
      end

      it 'shows remaining players needed to reach capacity' do
        client2 = create_and_accept_new_client
        client2.capture_output
        room.add_user(create_user(player2_name))

        expect(client1.capture_output).to match(/waiting.*#{capacity - room.num_players}/i)
        expect(client2.capture_output).to match(/waiting.*#{capacity - room.num_players}/i)
      end

      context 'when room reaches capacity' do
        it 'does not show waiting for 0 more players message' do
          client2 = create_and_accept_new_client
          room.add_user(create_user(player2_name))

          client3 = create_and_accept_new_client
          room.add_user(create_user(player3_name))

          expect(client1.capture_output).to_not match(/waiting.*0/i)
          expect(client2.capture_output).to_not match(/waiting.*0/i)
          expect(client3.capture_output).to_not match(/waiting.*0/i)
        end

        it 'shows all players joined message to all clients' do
          client2 = create_and_accept_new_client
          room.add_user(create_user(player2_name))

          client3 = create_and_accept_new_client
          room.add_user(create_user(player3_name))

          expect(client1.capture_output).to match(/all/i)
          expect(client2.capture_output).to match(/all/i)
          expect(client3.capture_output).to match(/all/i)
        end
      end
    end
  end

  describe '#run_room_if_possible' do
    let(:starting_regex) { /starting/i }

    let!(:client1) { create_and_accept_new_client }
    let!(:client2) { create_and_accept_new_client }
    let!(:client3) { create_and_accept_new_client }

    context 'when room is not full' do
      let!(:unfull_room) do
        Room.new(create_user(player1_name), capacity: capacity, id: room_id)
      end

      before do
        client1.capture_output
        client2.capture_output
        client3.capture_output
        unfull_room.run_room_if_possible
      end

      it 'does not create or start a game' do
        expect(unfull_room.game).to be_nil
        expect(client1.capture_output).to_not match(starting_regex)
      end
    end

    context 'when room is full but not started' do
      let!(:unstarted_room) do
        Room.new(create_user(player1_name), capacity: capacity, id: room_id)
      end

      before do
        unstarted_room.add_user(create_user(player2_name))
        unstarted_room.add_user(create_user(player3_name))
        client1.capture_output
        client2.capture_output
        client3.capture_output
      end

      it 'shows starting message to all users' do
        unstarted_room.run_room_if_possible

        expect(client1.capture_output).to match(starting_regex)
        expect(client2.capture_output).to match(starting_regex)
        expect(client3.capture_output).to match(starting_regex)
      end

      it 'creates a new game' do
        unstarted_room.run_room_if_possible

        expect(unstarted_room.game).to_not be_nil
      end

      it 'starts the game' do
        expect_any_instance_of(Game).to receive(:start)
        unstarted_room.run_room_if_possible
      end
    end

    context 'when room is full and started' do
      let!(:room) do
        Room.new(create_user(player1_name), capacity: capacity, id: room_id)
      end

      before do
        room.add_user(create_user(player2_name))
        room.add_user(create_user(player3_name))
        client1.capture_output
        client2.capture_output
        client3.capture_output
        room.start_game
      end

      it 'calls #run_started_game' do
        expect(room).to receive(:run_started_game)
        room.run_room_if_possible
      end
    end
  end
end
