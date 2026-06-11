require 'socket'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'
require_relative '../lib/client'

describe SocketServer do
  let!(:server) { SocketServer.new }
  let(:prompt_regex) { /(\s*\S*)*#{Client::INPUT_SYMBOL}/ }

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

  def question_regex(regex)
    Regexp.new(regex.source + prompt_regex.source)
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
    let!(:client1) { create_and_accept_new_client }
    let!(:controller) { server.controller }

    context 'on host' do
      it 'asks for number of players' do
        controller.ready?
        expect(client1.capture_output).to match(question_regex(/player/))
      end

      it 'asks only once' do
        controller.ready?
        client1.capture_output
        controller.ready?
        expect(client1.capture_output).to_not match(question_regex(/player/))
      end
    end

    context 'after player count is entered' do
      let(:valid_player_count_input) { '2' }
      let!(:client2) { create_and_accept_new_client }

      before do
        client1.provide_input(valid_player_count_input)
        controller.ready?
      end

      it 'asks all players for name' do
        expect(client1.capture_output).to match(question_regex(/name/))
        expect(client2.capture_output).to match(question_regex(/name/))
      end

      it 'asks each player name only once' do
        client1.capture_output
        client2.capture_output

        controller.ready?

        expect(client1.capture_output).to_not match(question_regex(/name/))
        expect(client2.capture_output).to_not match(question_regex(/name/))
      end
    end

    context 'player count is not entered' do
      it 'is not ready' do
        expect(controller).not_to be_ready
      end
    end

    context 'player count is entered' do
      before do
        client1.provide_input('2')
        controller.ready?
      end

      context 'when player count is NOT met' do
        it 'is not ready' do
          expect(controller).to_not be_ready
        end
      end

      context 'when player count is met' do
        let!(:client2) { create_and_accept_new_client }

        context 'players do not have names' do
          it 'is not ready' do
            expect(controller).to_not be_ready
          end
        end

        context 'one player has a name' do
          it 'is not ready' do
            client1.provide_input('Jeff')

            expect(controller).to_not be_ready
          end
        end

        context 'all players have a name' do
          it 'is ready' do
            client1.provide_input('Jeff')
            client2.provide_input('Bob')

            expect(controller).to be_ready
          end
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
