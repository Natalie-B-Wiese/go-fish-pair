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

  describe '#accept_new_client' do
    context 'with multiple clients' do
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
      let!(:client1) { create_and_accept_new_client }
      let!(:controller) { server.controller }
      it 'asks for number of players' do
        server.ready?
        expect(client1.capture_output).to match(/player(\s*\S*)*#{Client::INPUT_SYMBOL}/i)
      end

      it 'asks only once' do
        server.ready?
        client1.capture_output
        server.ready?
        expect(client1.capture_output).to_not match(/player(\s*\S*)*#{Client::INPUT_SYMBOL}/i)
      end

      context 'player count is entered but not met' do
        it 'does not run game' do
          client1.provide_input('2')
          server.ready?
          expect(client1.capture_output).to_not match(/game is starting/i)
        end
      end

      context 'player count is met' do
        it 'starts a game' do
          create_and_accept_new_client
          client1.provide_input('2')
          server.ready?
          expect(controller.desired_player_count).to eq(controller.num_players)
          expect(client1.capture_output).to match(/game is starting/i)
        end
      end

      context 'player count is NOT met' do
        it 'does not start a game' do
          server.ready?
          expect(client1.capture_output).to_not match(/game is starting/i)
        end
      end
    end
  end
end
