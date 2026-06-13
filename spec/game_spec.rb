require_relative '../lib/go_fish/game'
require_relative '../lib/deck'
require_relative '../lib/card'
require_relative '../lib/go_fish/player'

describe Game do
  let(:player1_name) { 'Jeff' }
  let(:player2_name) { 'Bob' }
  let(:player3_name) { 'Billy' }
  let(:player4_name) { 'Batman' }

  let!(:player1) { Player.new(player1_name) }
  let!(:player2) { Player.new(player2_name) }
  let!(:player3) { Player.new(player3_name) }
  let!(:player4) { Player.new(player4_name) }

  describe '#start' do
    context 'with 2 or 3 players' do
      let(:players) { [player1, player2] }
      let(:game) { described_class.new(players) }

      it "deals #{Game::SMALL_GAME_CARDS} cards to each player" do
        game.start
        expect(player1.cards.length).to eq Game::SMALL_GAME_CARDS
        expect(player2.cards.length).to eq Game::SMALL_GAME_CARDS
      end

      it 'cards are shuffled' do
        expect(game.deck).to receive(:shuffle)
        game.start
      end
    end

    context 'with 4 or more players' do
      let(:players) { [player1, player2, player3, player4] }
      let(:game) { described_class.new(players) }

      before do
        game.start
      end

      it "deals #{Game::BIG_GAME_CARDS} cards to each player" do
        expect(player1.cards.length).to eq Game::BIG_GAME_CARDS
        expect(player2.cards.length).to eq Game::BIG_GAME_CARDS
        expect(player3.cards.length).to eq Game::BIG_GAME_CARDS
        expect(player4.cards.length).to eq Game::BIG_GAME_CARDS
      end

      it 'cards are shuffled' do
        expect(game.deck).to receive(:shuffle)
        game.start
      end
    end
  end

  xdescribe '#play_turn' do
    let(:players) { [player1, player2, player3] }
    let(:game) { Game.new(players) }

    before do
      game.deck.cards = [Card.new('3', 'Clubs'), Card.new('A', 'Diamonds')]
      player1.cards = [Card.new('A', 'Spades'), Card.new('5', 'Hearts'), Card.new('3', 'Spades')]
      player2.cards = [Card.new('A', 'Hearts'), Card.new('2', 'Diamonds', Card.new('A', 'Clubs'))]
      player3.cards = [Card.new('5', 'Diamonds')]
    end

    context 'when opponent has that card' do
    end

    context 'when opponent does not have that card' do
    end

    context 'when player makes a book' do
    end

    context 'when player receives card they requested' do
    end

    context 'when player does not get desired card and does not make a book' do
      it 'switches turns' do
        expect(game.current_player_index).to eq 1
      end
    end
  end

  xdescribe '#request_deck_card' do
    let(:players) { [player1, player2] }

    let(:game) { described_class.new(players) }

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
        player1.add_cards([ace_spades, ace_clubs])
        game.deck.cards = [other_card, ace_diamonds]
      end

      it 'removes the card from the top of the deck' do
        game.request_deck_card('A')
        expect(game.deck.cards).to_not include other_card
      end

      it 'gives the card to the player' do
        game.request_deck_card('A')
        expect(player1.cards).to include other_card
      end

      it 'switches turn' do
        game.request_deck_card('A')
        expect(game.current_player_index).to eq player2_index
      end
    end

    context 'gets correct card' do
      before do
        player1.add_cards([ace_spades, ace_clubs])
        game.deck.cards = [ace_diamonds, other_card]
      end

      it 'removes the card from the top of the deck' do
        game.request_deck_card('A')
        expect(game.deck.cards).to_not include ace_diamonds
      end

      it 'gives the card to the player' do
        game.request_deck_card('A')
        expect(player1.cards).to include ace_diamonds
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

    let(:players) { [current_user, opponent] }

    let(:game) { described_class.new(players) }

    let(:request_rank) { 'A' }
    let(:incorrect_rank) { '5' }
    let(:good_card) { Card.new(request_rank, 'Clubs') }
    let(:other_card) { Card.new(incorrect_rank, 'Spades') }

    before do
      current_user.add_card(Card.new(request_rank, 'Spades'))
    end

    context 'opponent not have card' do
      before do
        opponent.add_card(other_card)
      end

      it 'does not remove opponent card' do
        game.request_card_from_player(request_rank, opponent.name)
        expect(opponent.cards).to include other_card
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
            game.request_card_from_player(request_rank, opponent)
            expect(game.current_client).to eq opponent
          end
        end
      end
    end

    context 'gets correct card' do
      before do
        opponent.add_cards([other_card, good_card])
      end

      it 'removes the card from opponent' do
        game.request_card_from_player(request_rank, opponent)
        expect(opponent.cards).to_not include good_card
      end

      it 'gives the card to the player' do
        game.request_card_from_player(request_rank, opponent)
        expect(current_user.cards).to include good_card
      end

      it 'does not switch turn' do
        game.request_card_from_player(request_rank, opponent)
        expect(game.current_user).to eq current_user
      end

      it 'works with multiple matching cards' do
        player_cards_before = current_user.cards.length
        opponent.add_card(Card.new(request_rank, 'Diamonds'))
        opponent_cards_before = opponent.cards.length
        matching_card_count = 2

        game.request_card_from_player(request_rank, opponent)

        expect(current_user.cards.length).to eq(player_cards_before + matching_card_count)
        expect(opponent.cards.length).to eq(opponent_cards_before - matching_card_count)
      end
    end
  end

  xdescribe '#winning_player' do
    let(:player1) { User.new(Client.new('socket'), Player.new('Jeff')) }
    let(:player2) { User.new(Client.new('socket'), Player.new('Bob')) }
    let(:user3) { User.new(Client.new('socket'), Player.new('Billy')) }
    let(:players) { [player1, player2, user3] }

    let(:game) { described_class.new(players) }

    context 'when one player has most books' do
      before do
        player1.player.books = []
        player2.player.books = [Book.new(5), Book.new(2), Book.new(10)]
        user3.player.books = [Book.new(12)]
      end

      it 'returns that player' do
        result = game.winning_player

        expect(result).to eq player2.player
      end
    end

    context 'when there is a tie' do
      before do
        player1.player.books = [Book.new(8), Book.new(5), Book.new(2)]
        player2.player.books = [Book.new(5), Book.new(3), Book.new(4)]
        user3.player.books = [Book.new(15)]
      end

      it 'returns user with most book and highest value book' do
        result = game.winning_player
        expect(result).to eq player1
      end
    end
  end
end
