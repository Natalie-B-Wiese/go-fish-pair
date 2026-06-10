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
    context 'with one client' do
      it 'adds client to array' do
        create_and_accept_new_client
        expect(server.controller.num_players).to eq 1
      end

      it 'shows welcome message' do
        client1 = create_and_accept_new_client
        expect(client1.capture_output).to match(/welcome/i)
      end
    end

    context 'with multiple clients' do
      it 'adds client to array' do
        create_and_accept_new_client
        create_and_accept_new_client
        expect(server.controller.num_players).to eq 2
      end

      it 'shows welcome message to all clients' do
        client1 = create_and_accept_new_client
        client2 = create_and_accept_new_client
        expect(client1.capture_output).to match(/welcome/i)
        expect(client2.capture_output).to match(/welcome/i)
      end
    end
  end

  describe '#ready?' do
    context 'on host' do
      it 'asks for number of players' do
        client1 = create_and_accept_new_client
        client1.capture_output

        server.ready?
        expect(client1.capture_output).to match(/player(\s*\S*)*#{Client::INPUT_SYMBOL}/i)
      end

      it 'asks only once' do
        client1 = create_and_accept_new_client
        client1.capture_output

        server.ready?
        client1.capture_output
        server.ready?
        expect(client1.capture_output).to be_empty
      end

      context 'when valid player count is met' do
        it 'starts a game' do
          server.ready?
          expect(client1.capture_output).to eq(/game starting/i)
        end
      end

      xcontext 'when invalid player count' do
        let(:invalid_player_count) { 'Banana' }

        it 'shows invalid message' do
          client1 = create_and_accept_new_client
          server.ready?
          client1.capture_output
          client1.provide_input(invalid_player_count)

          server.ready?

          expect(client1.capture_output).to match(/invalid/i)
        end

        it 'asks again for input' do
          client1 = create_and_accept_new_client
          server.ready?
          client1.capture_output

          client1.provide_input(invalid_player_count)

          server.ready?
          expect(client1.capture_output).to match(/player(\s*\S*)*#{Client::INPUT_SYMBOL}/i)
        end
      end
    end
  end
end
