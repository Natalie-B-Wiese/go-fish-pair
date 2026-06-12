require_relative '../lib/game'
require_relative '../lib/deck'
require_relative '../lib/card'
require_relative '../lib/user'
require_relative '../lib/client'
require_relative '../lib/player'

describe Game do
  before do
    allow_any_instance_of(Client).to receive(:puts)
  end

  # creates a deck
  # deals the deck between the two players
  # the deck should be shuffled
  describe '#initialize' do
    # (client, player)
    let(:user1) { User.new(Client.new('socket'), Player.new('Jeff')) }
    let(:user2) { User.new(Client.new('socket'), Player.new('Bob')) }

    let(:users) { [user1, user2] }

    let(:game) { described_class.new(users) }

    it 'contains an array of users' do
      expect(game.users).to eq users
    end

    it 'creates a deck of cards' do
      expect(game.deck).to be_a(Deck)
    end

    it 'sets current_player_index to 0' do
      expect(game.current_player_index).to eq 0
    end
  end

  describe '#start' do
    let(:user1) { User.new(Client.new('socket'), Player.new('Jeff')) }
    let(:user2) { User.new(Client.new('socket'), Player.new('Bob')) }
    let(:user3) { User.new(Client.new('socket'), Player.new('Billy')) }
    let(:user4) { User.new(Client.new('socket'), Player.new('Batman')) }

    # shuffles a deck
    # deals the deck to the players
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

  describe '#request_deck_card' do
    let(:user1) { User.new(Client.new('socket'), Player.new('Jeff')) }
    let(:user2) { User.new(Client.new('socket'), Player.new('Bob')) }

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

  describe '#request_card_from_user' do
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

  describe '#winning_player' do
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
