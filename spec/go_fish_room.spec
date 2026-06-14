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

  def clear_clients_output
    client1.capture_output
    client2.capture_output
    client3.capture_output
  end

  before do
    room.add_user(create_user(player2_name))
    room.add_user(create_user(player3_name))
    room.start_game

    clear_clients_output
  end

  # run_room_if_possible
  describe '#play_round' do
    before do
      room.play_round
    end

    it 'shows all players their hand' do
      expect(client1.capture_output).to match(/of/i)
      expect(client2.capture_output).to match(/of/i)
    end

    it 'shows all players their hand only once' do
      clear_clients_output
      room.play_round

      expect(client1.capture_output).to_not match(/of/i)
      expect(client2.capture_output).to_not match(/of/i)
    end

    context 'on first player turn' do
      it 'shows all clients whose turn it is' do
        expect(client1.capture_output).to match(/your turn/)
        expect(client2.capture_output).to match(/#{player1_name}'s turn/)
        expect(client3.capture_output).to match(/#{player1_name}'s turn/)
      end

      it 'shows all clients whose turn it is only once' do
        clear_clients_output
        room.play_round

        expect(client1.capture_output).to_not match(/your turn/)
        expect(client2.capture_output).to_not match(/#{player1_name}'s turn/)
        expect(client3.capture_output).to_not match(/#{player1_name}'s turn/)
      end

      context 'when player has no cards but deck has cards' do
        let(:card_taken) { Card.new('5', 'Hearts') }
        before do
          room.users[0].player.cards = []
          room.game.deck.cards = [card_taken]
          room.play_round
        end

        it 'player draws from the deck' do
          expect(room.users[0].player.cards).to include card_taken
          expect(room.game.deck.cards).to_not include card_taken
        end

        it 'shows result to all players' do
          expect(client1.capture_output).to match(/you .* #{card_taken} .* deck/i)
          expect(client2.capture_output).to match(/#{player1_name} .* a card .* deck/i)
          expect(client3.capture_output).to match(/#{player1_name} .* a card .* deck/i)
        end

        it 'player turn continues' do
          expect(client1.capture_output).to match(question_regex(/rank/))
        end
      end

      # TODO: If player is out of cards and there there are no cards left in the stock, they are out of the game.

      context 'before getting valid rank' do
        it 'asks player 1 for a rank' do
          expect(client1.capture_output).to match(question_regex(/rank/))
        end

        it 'does not ask other players for a rank' do
          expect(client2.capture_output).to_not match(question_regex(/rank/))
          expect(client3.capture_output).to_not match(question_regex(/rank/))
        end

        it 'it will not ask rank again until user provided input' do
          client1.capture_output
          room.play_round
          expect(client1.capture_output).not_to match(question_regex(/rank/))
        end

        context 'when current player provides rank they do not have' do
          before do
            room.game.current_player.cards = [Card.new('A', 'Spades')]
            rank_not_have = '2'
            client1.provide_input(rank_not_have)
            client1.capture_output

            room.play_round
          end

          it 'shows invalid message' do
            expect(client1.capture_output).to match(/invalid/i)
          end

          it 'will ask for rank again on next run' do
            clear_clients_output
            room.play_round
            expect(client1.capture_output).to match(question_regex(/rank/))
          end
        end

        context 'when current player provides rank they have' do
          before do
            room.game.current_player.cards = [Card.new('A', 'Spades')]
            rank_have = 'A'
            client1.provide_input(rank_have)
            client1.capture_output

            room.play_round
          end

          it 'does not show invalid message' do
            expect(client1.capture_output).to_not match(/invalid/i)
          end

          it 'will not ask for rank again on next run' do
            clear_clients_output
            room.play_round
            expect(client1.capture_output).to_not match(question_regex(/rank/))
          end
        end
      end

      context 'after getting valid rank' do
        let(:valid_rank) { 'A' }
        before do
          room.game.current_player.cards = [Card.new('A', 'Spades')]
          client1.provide_input(valid_rank)
          client1.capture_output

          room.play_round
        end

        it 'shows player 1 a list of users and ids to request from excluding self' do
          result = client1.capture_output
          expect(result).to match(/2: #{player2_name}/)
          expect(result).to match(/3: #{player3_name}/)
        end

        it 'does not show the list of players to the other players' do
          expect(client2.capture_output).to_not match(/3:#{player3_name}/)
          expect(client3.capture_output).to_not match(/2:#{player2_name}/)
        end

        it 'asks current player for a player id' do
          expect(client1.capture_output).to match(question_regex(/player/))
        end

        it 'does not ask other players for a player id' do
          expect(client2.capture_output).to_not match(question_regex(/player/))
          expect(client3.capture_output).to_not match(question_regex(/player/))
        end

        it 'will not ask again until user provided an input' do
          client1.capture_output
          room.play_round
          expect(client1.capture_output).not_to match(question_regex(/player/))
        end

        context 'when player id is own player id' do
          before do
            own_player_id = '1'
            client1.provide_input(own_player_id)
            client1.capture_output

            room.play_round
          end

          it 'shows invalid message' do
            expect(client1.capture_output).to match(/invalid/i)
          end

          it 'will ask for player again on next run' do
            room.play_round
            expect(client1.capture_output).to match(question_regex(/player/))
          end
        end

        context 'when player with that id does not exist' do
          before do
            invalid_player_id = '30'
            client1.provide_input(invalid_player_id)
            client1.capture_output

            room.play_round
          end

          it 'shows invalid message' do
            expect(client1.capture_output).to match(/invalid/i)
          end

          it 'will ask for player again on next run' do
            room.play_round
            expect(client1.capture_output).to match(question_regex(/player/))
          end
        end

        context 'when player with that id exists but is out of cards' do
          before do
            player_index_without_cards = 1
            room.users[player_index_without_cards].player.cards = []

            out_of_cards_player_id = (player_index_without_cards + 1).to_s

            client1.provide_input(out_of_cards_player_id)
            client1.capture_output

            room.play_round
          end

          it 'shows out of cards message' do
            expect(client1.capture_output).to match(/cards/i)
          end

          it 'will ask for player again on next run' do
            room.play_round
            expect(client1.capture_output).to match(question_regex(/player/))
          end
        end

        context 'when current player provides valid opponent id' do
          let!(:cards_before) { room.game.current_player.cards }
          before do
            valid_player_id = '2'
            client1.provide_input(valid_player_id)
            client1.capture_output

            room.play_round
          end

          it 'does not show invalid message' do
            expect(client1.capture_output).to_not match(/invalid/i)
          end

          it 'preforms the move' do
            expect(room.game.current_player.cards).not_to eq cards_before
          end

          it 'shows move result to all players' do
            client1_result = client1.capture_output
            client2_result = client2.capture_output
            client3_result = client3.capture_output

            expect(client1_result).to match(/you.*#{valid_rank}.*#{player2_name}/i)
            expect(client2_result).to match(/#{player1_name}.*#{valid_rank}.*you/i)
            expect(client3_result).to match(/#{player1_name}.*#{valid_rank}.*#{player2_name}/i)
          end
        end
      end
    end
  end
end
