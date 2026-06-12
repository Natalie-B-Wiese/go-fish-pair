require_relative '../lib/game'
require_relative '../lib/deck'
require_relative '../lib/card'
require_relative '../lib/user'
require_relative '../lib/client'
require_relative '../lib/player'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'

describe Game do
  let!(:server) { SocketServer.new }

  before(:each) do
    server.start
    sleep 0.1 # Ensure server is ready for clients
  end

  after(:each) do
    server.stop
  end

  let!(:client1) { create_and_accept_new_client }
  let!(:client2) { create_and_accept_new_client }
  let!(:client3) { create_and_accept_new_client }
  let!(:client4) { create_and_accept_new_client }

  let(:player1_name) { 'Jeff' }
  let(:player2_name) { 'Bob' }
  let(:player3_name) { 'Billy' }
  let(:player4_name) { 'Batman' }

  let!(:user1) { User.new(server.pending_clients[0], Player.new(player1_name)) }
  let!(:user2) { User.new(server.pending_clients[1], Player.new(player2_name)) }
  let!(:user3) { User.new(server.pending_clients[2], Player.new(player3_name)) }
  let!(:user4) { User.new(server.pending_clients[3], Player.new(player4_name)) }

  def create_and_accept_new_client
    client = MockSocketClient.new
    server.accept_new_client
    client
  end

  def question_regex(regex)
    Regexp.new(regex.source + /.*#{Client::INPUT_SYMBOL}/.source)
  end

  describe '#start' do
    # shuffles a deck
    # deals the deck to the players
    it 'shows starting message to all players' do
      users = [user1, user2]
      game = Game.new(users)

      game.start

      expect(client1.capture_output).to match(/starting/i)
      expect(client2.capture_output).to match(/starting/i)
    end

    context 'with 2 or 3 players' do
      let(:users) { [user1, user2] }
      let(:game) { described_class.new(users) }

      before do
        game.start
      end

      it "deals #{Game::SMALL_GAME_CARDS} cards to each player" do
        expect(user1.player.cards.length).to eq Game::SMALL_GAME_CARDS
        expect(user2.player.cards.length).to eq Game::SMALL_GAME_CARDS
      end
    end

    context 'with 4 or more players' do
      let(:users) { [user1, user2, user3, user4] }
      let(:game) { described_class.new(users) }

      before do
        game.start
      end

      it "deals #{Game::BIG_GAME_CARDS} cards to each player" do
        expect(user1.player.cards.length).to eq Game::BIG_GAME_CARDS
        expect(user2.player.cards.length).to eq Game::BIG_GAME_CARDS
        expect(user3.player.cards.length).to eq Game::BIG_GAME_CARDS
        expect(user4.player.cards.length).to eq Game::BIG_GAME_CARDS
      end
    end
  end

  describe '#play_turn' do
    let(:users) { [user1, user2] }
    let(:game) { Game.new(users) }

    let(:card1) { Card.new('A', 'Spades') }
    let(:card2) { Card.new('5', 'Hearts') }

    let(:card3) { Card.new('A', 'Hearts') }
    let(:card4) { Card.new('A', 'Diamonds') }
    let(:card5) { Card.new('A', 'Clubs') }

    before do
      game.start
      game.users[0].player.cards = [card1, card2]
      game.users[1].player.cards = [card3, card4, card5]

      client1.capture_output
      client2.capture_output

      game.play_turn
    end

    it 'shows all players their hand' do
      expect(client1.capture_output).to match(/of/i)
      expect(client2.capture_output).to match(/of/i)
    end

    it 'shows whose turn it is' do
      expect(client1.capture_output).to match(/your turn/i)
      expect(client2.capture_output).to match(/#{player1_name}'s turn/)
    end

    it 'asks current player for a rank' do
      expect(client1.capture_output).to match(question_regex(/rank/))
    end

    it 'asks for rank only once' do
      client1.capture_output
      game.play_turn
      expect(client1.capture_output).not_to match(question_regex(/rank/))
    end

    context 'when current player provides rank they do not have' do
      before do
        rank_not_have = '2'
        client1.provide_input(rank_not_have)
        client1.capture_output

        game.play_turn
      end

      it 'shows invalid message' do
        expect(client1.capture_output).to match(/invalid/i)
      end

      it 'will ask for rank again on next run' do
        game.play_turn
        expect(client1.capture_output).to match(question_regex(/rank/))
      end
    end

    context 'when current player provides a rank they have' do
      before do
        rank_have = 'A'
        client1.provide_input(rank_have)
        client1.capture_output

        game.play_turn
      end

      it 'does not ask for rank' do
        game.play_turn
        expect(client1.capture_output).to_not match(question_regex(/rank/))
      end

      it 'shows a list of users and ids to request from exluding self' do
        result = client1.capture_output
        expect(result).to match(/"2: #{player2_name}"/)
      end

      it 'asks for a player id' do
        expect(client1.capture_output).to match(question_regex(/player/))
      end

      it 'asks for player id only once' do
        client1.capture_output
        game.play_turn
        expect(client1.capture_output).not_to match(question_regex(/player/))
      end

      context 'when player id is invalid' do
        before do
          invalid_player_id = '1'
          client1.provide_input(invalid_player_id)
          client1.capture_output

          game.play_turn
        end

        it 'shows invalid message' do
          expect(client1.capture_output).to match(/invalid/i)
        end

        it 'will ask for player again on next run' do
          game.play_turn
          expect(client1.capture_output).to match(question_regex(/player/))
        end
      end
    end

    context 'when current player has chosen a valid rank and opponent' do
      before do
        rank_have = 'A'
        client1.provide_input(rank_have)
        client1.capture_output

        game.play_turn

        valid_player_id = '2'
        client1.provide_input(valid_player_id)
        client1.capture_output

        game.play_turn
      end

      it 'it shows the result of the move to all users' do
        expect(client1.capture_output).to match(/requested a A.*from.*#{player2_name}/)
        expect(client2.capture_output).to match(/#{player1_name} requested a A.*from you/)
      end
    end

    context 'when opponent has that card' do
      before do
        rank_have = 'A'
        client1.provide_input(rank_have)
        client1.capture_output

        game.play_turn

        valid_player_id = '2'
        client1.provide_input(valid_player_id)
        client1.capture_output

        game.play_turn
      end

      it 'it gives the card' do
        expect(client1.capture_output).to match(/gave/)
        expect(client2.capture_output).to match(/gave/)
      end

      it 'does not do deck action' do
        expect(client1.capture_output).to_not match(/deck/)
        expect(client2.capture_output).to_not match(/deck/)
      end
    end

    context 'when opponent does not have that card' do
      before do
        rank_have = '5'
        client1.provide_input(rank_have)
        client1.capture_output

        game.play_turn

        valid_player_id = '2'
        client1.provide_input(valid_player_id)
        client1.capture_output

        game.play_turn
      end

      it 'it pulls from the deck' do
        expect(client1.capture_output).to match(/deck/)
        expect(client2.capture_output).to match(/deck/)
      end
    end
  end

  xdescribe '#request_deck_card' do
    let(:users) { [user1, user2] }

    let(:game) { described_class.new(users) }

    let(:ace_spades) { Card.new('A', 'Spades') }
    let(:ace_clubs)  { Card.new('A', 'Clubs') }

    let(:ace_diamonds) { Card.new('A', 'Diamonds') }
    let(:other_card) { Card.new('5', 'Spades') }

    let(:player1_index) { 0 }
    let(:player2_index) { 1 }

    context 'deck is empty' do
      before do
        game.deck.cards = []
      end

      it 'switches turn' do
        game.request_deck_card('A')
        expect(game.current_player_index).to eq player2_index
      end
    end

    context 'does not get requested card' do
      before do
        user1.player.add_cards([ace_spades, ace_clubs])
        game.deck.cards = [other_card, ace_diamonds]
      end

      it 'removes the card from the top of the deck' do
        game.request_deck_card('A')
        expect(game.deck.cards).to_not include other_card
      end

      it 'gives the card to the player' do
        game.request_deck_card('A')
        expect(user1.player.cards).to include other_card
      end

      it 'switches turn' do
        game.request_deck_card('A')
        expect(game.current_player_index).to eq player2_index
      end
    end

    context 'gets correct card' do
      before do
        user1.player.add_cards([ace_spades, ace_clubs])
        game.deck.cards = [ace_diamonds, other_card]
      end

      it 'removes the card from the top of the deck' do
        game.request_deck_card('A')
        expect(game.deck.cards).to_not include ace_diamonds
      end

      it 'gives the card to the player' do
        game.request_deck_card('A')
        expect(user1.player.cards).to include ace_diamonds
      end

      it 'does not switch turn' do
        game.request_deck_card('A')
        expect(game.current_player_index).to eq player1_index
      end
    end
  end

  xdescribe '#request_card_from_user' do
    let(:current_user) { User.new(Client.new('socket'), Player.new('Jeff')) }
    let(:opponent) { User.new(Client.new('socket'), Player.new('Bob')) }

    let(:users) { [current_user, opponent] }

    let(:game) { described_class.new(users) }

    let(:request_rank) { 'A' }
    let(:incorrect_rank) { '5' }
    let(:good_card) { Card.new(request_rank, 'Clubs') }
    let(:other_card) { Card.new(incorrect_rank, 'Spades') }

    before do
      current_user.player.add_card(Card.new(request_rank, 'Spades'))
    end

    context 'opponent not have card' do
      before do
        opponent.player.add_card(other_card)
      end

      it 'does not remove opponent card' do
        game.request_card_from_player(request_rank, opponent.name)
        expect(opponent.player.cards).to include other_card
      end

      context 'goes fish' do
        context 'gets requested card' do
          before do
            game.deck.cards = [good_card]
          end

          it 'does not switch turn' do
            game.request_card_from_player(request_rank, opponent.name)
            expect(game.current_client).to eq client
          end
        end

        context 'not get card' do
          before do
            game.deck.cards = [Card.new(incorrect_rank, 'Clubs')]
          end

          it 'switches turn' do
            game.request_card_from_player(request_rank, opponent.name)
            expect(game.current_client).to eq opponent
          end
        end
      end
    end

    context 'gets correct card' do
      before do
        opponent.player.add_cards([other_card, good_card])
      end

      it 'removes the card from opponent' do
        game.request_card_from_player(request_rank, opponent.name)
        expect(opponent.player.cards).to_not include good_card
      end

      it 'gives the card to the player' do
        game.request_card_from_player(request_rank, opponent.name)
        expect(current_user.player.cards).to include good_card
      end

      it 'does not switch turn' do
        game.request_card_from_player(request_rank, opponent.name)
        expect(game.current_user).to eq current_user
      end

      it 'works with multiple matching cards' do
        player_cards_before = current_user.player.cards.length
        opponent.player.add_card(Card.new(request_rank, 'Diamonds'))
        opponent_cards_before = opponent.player.cards.length
        matching_card_count = 2

        game.request_card_from_player(request_rank, opponent.name)

        expect(current_user.player.cards.length).to eq(player_cards_before + matching_card_count)
        expect(opponent.player.cards.length).to eq(opponent_cards_before - matching_card_count)
      end
    end
  end

  xdescribe '#winning_player' do
    let(:user1) { User.new(Client.new('socket'), Player.new('Jeff')) }
    let(:user2) { User.new(Client.new('socket'), Player.new('Bob')) }
    let(:user3) { User.new(Client.new('socket'), Player.new('Billy')) }
    let(:users) { [user1, user2, user3] }

    let(:game) { described_class.new(users) }

    context 'when one player has most books' do
      before do
        user1.player.books = []
        user2.player.books = [Book.new(5), Book.new(2), Book.new(10)]
        user3.player.books = [Book.new(12)]
      end

      it 'returns that player' do
        result = game.winning_player

        expect(result).to eq user2.player
      end
    end

    context 'when there is a tie' do
      before do
        user1.player.books = [Book.new(8), Book.new(5), Book.new(2)]
        user2.player.books = [Book.new(5), Book.new(3), Book.new(4)]
        user3.player.books = [Book.new(15)]
      end

      it 'returns user with most book and highest value book' do
        result = game.winning_player
        expect(result).to eq user1
      end
    end
  end
end
