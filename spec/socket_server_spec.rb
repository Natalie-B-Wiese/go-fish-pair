require 'socket'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'
require_relative '../lib/client'

describe SocketServer do
  let!(:server) { SocketServer.new }

  before(:each) do
    server.start
    sleep 0.1 # Ensure server is ready for clients
  end

  after(:each) do
    server.stop
  end

  def question_regex(regex)
    Regexp.new(regex.source + /(\s*\S*)*#{Client::INPUT_SYMBOL}/.source)
  end

  # creates and accepts a new client and gives the client a name
  def create_named_client(name)
    client = create_and_accept_new_client
    client.provide_input(name)

    server.handle_pending_clients
    client1.capture_output

    client
  end

  # NOTE: host client should already be named
  def create_room(host_client, capacity:, room_id:)
    # make client create room
    host_client.provide_input('create')
    server.handle_pending_clients

    host_client.provide_input(capacity)
    server.handle_pending_clients
    host_client.capture_output

    room = server.rooms.last
    room.instance_variable_set(:@id, room_id)
    room
  end

  # makes a named client join a room
  def join_room(client, room_id)
    client.provide_input('join')
    server.handle_pending_clients
    client.capture_output
    client.provide_input(room_id)
    server.handle_pending_clients
  end

  def create_and_accept_new_client
    client = MockSocketClient.new
    server.accept_new_client
    client
  end

  it 'is not listening on a port before it is started' do
    server.stop
    expect { MockSocketClient.new }.to raise_error(Errno::ECONNREFUSED)
  end

  describe '#accept_new_client' do
    let!(:client1) { create_and_accept_new_client }
    it 'adds client to pending clients array' do
      expect(server.pending_clients.length).to eq 1
    end

    it 'shows welcome message to client' do
      expect(client1.capture_output).to match(/welcome/i)
    end
  end

  describe '#handle_pending_clients' do
    let!(:client1) { create_and_accept_new_client }
    let(:valid_name) { 'Natalie' }

    context 'before client has a valid name' do
      it 'asks client for a name' do
        server.handle_pending_clients
        expect(client1.capture_output).to match(question_regex(/name/))
      end

      it 'asks only once' do
        server.handle_pending_clients
        client1.capture_output

        expect(client1.capture_output).to_not match(question_regex(/name/))
      end

      context 'when blank name provided' do
        before do
          invalid_input = ' '
          client1.provide_input(invalid_input)
          server.handle_pending_clients
        end

        it 'shows an error' do
          expect(client1.capture_output).to match(/invalid/i)
        end

        it 'asks again for name on next run' do
          server.handle_pending_clients
          expect(client1.capture_output).to match(question_regex(/name/))
        end
      end
    end

    context 'client has a valid name' do
      let(:join_or_create_regex) { question_regex(/CREATE or JOIN/) }

      before do
        client1.provide_input(valid_name)
        server.handle_pending_clients
      end

      it 'asks user whether to join or create a room' do
        server.handle_pending_clients
        result = client1.capture_output
        expect(result).to match(join_or_create_regex)
      end

      it 'asks only once' do
        server.handle_pending_clients
        client1.capture_output

        server.handle_pending_clients
        result = client1.capture_output
        expect(result).to_not match(join_or_create_regex)
      end

      it 'shows error when input is not equal to JOIN or CREATE' do
        client1.provide_input('banana')
        server.handle_pending_clients
        expect(client1.capture_output).to match(/invalid/i)
      end
    end

    context 'named client chose to join a room' do
      let(:room_code_regex) { question_regex(/room code/) }

      before do
        # give client a name
        client1.provide_input(valid_name)
        server.handle_pending_clients
        client1.capture_output

        # make client join
        client1.provide_input('join')
        server.handle_pending_clients
      end

      it 'asks user for room code' do
        server.handle_pending_clients
        result = client1.capture_output
        expect(result).to match(room_code_regex)
      end

      it 'asks only once' do
        server.handle_pending_clients
        client1.capture_output

        server.handle_pending_clients
        result = client1.capture_output
        expect(result).to_not match(room_code_regex)
      end

      it 'shows error when room with that id does not exist or is at capacity' do
        client1.provide_input('1010210')
        server.handle_pending_clients
        expect(client1.capture_output).to match(/invalid/i)
      end
    end

    context 'named client chose to create a room' do
      before do
        # give client a name
        client1.provide_input(valid_name)
        server.handle_pending_clients
        client1.capture_output

        # make client create room
        client1.provide_input('create')
        server.handle_pending_clients
      end

      it 'asks for number of players' do
        expect(client1.capture_output).to match(question_regex(/players/))
      end

      it 'asks only once for number of players' do
        client1.capture_output
        server.handle_pending_clients
        expect(client1.capture_output).to_not match(question_regex(/players/))
      end

      it 'shows error when number of players is not positive' do
        client1.provide_input('0')
        server.handle_pending_clients
        expect(client1.capture_output).to match(/invalid/i)
      end
    end

    context 'named client successfully joins a room as host' do
      # client is removed from list
      # client receives welcome message
      # a new room is created
      before do
        # give client a name
        client1.provide_input(valid_name)
        server.handle_pending_clients
        client1.capture_output

        # make client create room
        client1.provide_input('create')
        server.handle_pending_clients

        client1.provide_input('2')
        server.handle_pending_clients
      end

      it 'creates a new room' do
        expect(server.rooms.length).to eq 1
      end

      it 'removes client from pending clients' do
        expect(server.pending_clients.length).to eq 0
      end
    end

    context 'when named client successfully joins an available room as visitor' do
      let(:room_id) { '1234' }
      let(:client2_name) { 'Henry' }

      let!(:client2) { create_named_client(client2_name) }

      before do
        client1.provide_input(valid_name)
        server.handle_pending_clients
        client1.capture_output

        create_room(client1, capacity: 2, room_id: room_id)

        join_room(client2, room_id)
      end

      it 'add the client to the room' do
        expect(server.rooms[0].num_players).to eq 2
      end

      it 'removes client from pending clients' do
        expect(server.pending_clients.length).to eq 0
      end
    end
  end
end
