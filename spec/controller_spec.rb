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
      let(:num_players_prompt_regex) { /player(\s*\S*)*#{Client::INPUT_SYMBOL}/i }

      it 'asks for number of players' do
        controller.ready?
        expect(client1.capture_output).to match(num_players_prompt_regex)
      end

      it 'asks only once' do
        controller.ready?
        client1.capture_output
        controller.ready?
        expect(client1.capture_output).to_not match(num_players_prompt_regex)
      end

      context 'player count is entered but not met' do
        it 'is not ready' do
          client1.provide_input('2')
          expect(controller).to_not be_ready
          # controller.ready?
          # expect(client1.capture_output).to_not match(/game is starting/i)
        end
      end

      context 'player count is met' do
        it 'is ready' do
          create_and_accept_new_client
          client1.provide_input('2')
          expect(controller).to be_ready
          # controller.try_run
          # expect(client1.capture_output).to match(/game is starting/i)
        end
      end

      context 'player count is NOT met' do
        it 'is not ready' do
          expect(controller).to_not be_ready
          # controller.try_run
          # expect(client1.capture_output).to_not match(/game is starting/i)
        end
      end
    end
  end

  describe '#started?' do
    let!(:controller) { server.controller }

    context 'before game is started' do
      it 'returns false' do
        expect(controller).to_not be_started
      end
    end

    context 'after game has been started' do
      before do
        controller.start_game
      end

      it 'returns true' do
        expect(controller).to be_started
      end
    end
  end
end
