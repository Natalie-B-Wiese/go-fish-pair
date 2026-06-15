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

  describe '#play_turn' do
    let(:players) { [player1, player2, player3] }
    let(:game) { Game.new(players) }

    context 'when opponent has that card' do
      before do
        player1.cards = [Card.new('5', 'Hearts')]
        player3.cards = [Card.new('5', 'Diamonds')]
      end

      context 'when opponent has 1 match' do
        let(:rank) { '5' }
        let(:opponent) { player3 }
        let(:taken_card) { Card.new(rank, 'Diamonds') }
        it 'takes from opponent and gives to player' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.cards).to include taken_card
          expect(opponent.cards).to_not include taken_card
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to eq [taken_card]
          expect(result.card_received_deck).to be_nil
          expect(result.was_book_made).to eq false
          expect(result.go_again?).to eq true
        end

        it 'does not switch turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player1
        end
      end

      context 'when opponent has more than one match' do
        before do
          player1.cards = [Card.new('A', 'Spades')]
          player2.cards = [Card.new('A', 'Hearts'), Card.new('A', 'Clubs')]
        end

        let(:rank) { 'A' }
        let(:opponent) { player2 }
        let!(:taken_card1) { opponent.cards[0] }
        let!(:taken_card2) { opponent.cards[1] }

        it 'takes from opponent and gives to player' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.cards).to include taken_card1
          expect(player1.cards).to include taken_card2

          expect(opponent.cards).to_not include taken_card1
          expect(opponent.cards).to_not include taken_card2
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to eq [taken_card1, taken_card2]
          expect(result.card_received_deck).to be_nil
          expect(result.was_book_made).to eq false
          expect(result.go_again?).to eq true
        end

        it 'does not switch turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player1
        end
      end

      context 'when player can make a book' do
        let(:rank) { 'A' }

        before do
          player1.cards = [Card.new(rank, 'Spades'), Card.new(rank, 'Hearts')]
          player2.cards = [Card.new(rank, 'Diamonds'), Card.new(rank, 'Clubs')]
        end

        let(:opponent) { player2 }
        let!(:card1) { player1.cards[0] }
        let!(:card2) { player1.cards[1] }
        let!(:card3) { player2.cards[0] }
        let!(:card4) { player2.cards[1] }

        it 'takes from both opponent and player' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.cards).to_not include card1
          expect(player1.cards).to_not include card2
          expect(player1.cards).to_not include card3
          expect(player1.cards).to_not include card4

          expect(opponent.cards).to_not include card1
          expect(opponent.cards).to_not include card2
          expect(opponent.cards).to_not include card3
          expect(opponent.cards).to_not include card4
        end

        it 'makes a book' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.book_count).to eq 1
          expect(opponent.book_count).to eq 0
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to eq [card3, card4]
          expect(result.card_received_deck).to be_nil
          expect(result.was_book_made).to eq true
          expect(result.go_again?).to eq true
        end

        it 'does not switch turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player1
        end
      end
    end

    context 'when go fish and success' do
      let(:opponent) { player2 }
      let(:taken_card) { Card.new(rank, 'Spades') }

      before do
        opponent.cards = [Card.new('8', 'Diamonds')]
      end

      context 'when player cannot make book' do
        let(:rank) { 'A' }

        before do
          game.deck.cards = [taken_card, Card.new('5', 'Clubs')]
          player1.cards = [Card.new(rank, 'Hearts')]
        end

        it 'takes from top of deck and gives to player' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.cards).to include taken_card
          expect(game.deck.cards).to_not include taken_card
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to eq taken_card
          expect(result.was_book_made).to eq false
          expect(result.go_again?).to eq true
        end

        it 'does not switch turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player1
        end
      end

      context 'when player can make a book' do
        let(:rank) { 'A' }

        before do
          player1.cards = [Card.new(rank, 'Spades'), Card.new(rank, 'Hearts'), Card.new(rank, 'Diamonds')]
          game.deck.cards = [taken_card]
        end

        it 'makes a book' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.book_count).to eq 1
          expect(opponent.book_count).to eq 0
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to eq taken_card
          expect(result.was_book_made).to eq true
          expect(result.go_again?).to eq true
        end

        it 'does not switch turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player1
        end
      end
    end

    context 'when go fish and fail' do
      let(:opponent) { player2 }
      let(:other_rank) { '5' }
      let(:rank) { 'A' }

      let(:taken_card) { Card.new(other_rank, 'Spades') }

      before do
        opponent.cards = [Card.new('8', 'Diamonds')]
      end

      context 'when player cannot make book' do
        before do
          game.deck.cards = [taken_card]
          player1.cards = [Card.new(rank, 'Hearts')]
        end

        it 'takes from top of deck and gives to player' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.cards).to include taken_card
          expect(game.deck.cards).to_not include taken_card
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to eq taken_card
          expect(result.was_book_made).to eq false
          expect(result.go_again?).to eq false
        end

        it 'switches turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player2
        end
      end

      context 'when player can make a book' do
        let(:rank) { 'A' }
        let(:taken_card) { Card.new(other_rank, 'Clubs') }

        before do
          player1.cards = [Card.new(rank, 'Hearts'), Card.new(other_rank, 'Spades'),
                           Card.new(other_rank, 'Hearts'), Card.new(other_rank, 'Diamonds')]
          game.deck.cards = [taken_card]
        end

        it 'makes a book' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(player1.book_count).to eq 1
          expect(opponent.book_count).to eq 0
        end

        it 'returns the correct turn result' do
          result = game.play_turn(rank: rank, opponent: opponent)
          expect(result.current_player).to eq player1
          expect(result.opponent_player).to eq opponent
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to eq taken_card
          expect(result.was_book_made).to eq true
          expect(result.go_again?).to eq true
        end

        it 'does not switch turns' do
          game.play_turn(rank: rank, opponent: opponent)
          expect(game.current_player).to eq player1
        end
      end
    end

    context 'when go fish and deck empty' do
      let(:opponent) { player2 }
      let(:rank) { 'A' }

      before do
        opponent.cards = [Card.new('8', 'Diamonds')]
        player1.cards = [Card.new(rank, 'Hearts')]
        game.deck.cards = []
      end
      it 'returns the correct turn result' do
        result = game.play_turn(rank: rank, opponent: opponent)
        expect(result.current_player).to eq player1
        expect(result.opponent_player).to eq opponent
        expect(result.rank_requested).to eq rank
        expect(result.cards_received_opponent).to be_empty
        expect(result.card_received_deck).to be_nil
        expect(result.was_book_made).to eq false
        expect(result.go_again?).to eq false
      end

      it 'switches turns' do
        game.play_turn(rank: rank, opponent: opponent)
        expect(game.current_player).to eq player2
      end
    end
  end

  describe '#request_deck_card' do
    let(:players) { [player1, player2] }

    let(:game) { described_class.new(players) }

    let(:card_taken) { Card.new('A', 'Spades') }
    let(:other_card) { Card.new('5', 'Spades') }

    let(:player1_index) { 0 }
    let(:player2_index) { 1 }

    context 'deck is empty' do
      before do
        game.deck.cards = []
      end

      it 'returns the correct turn result' do
        result = game.request_deck_card
        expect(result.current_player).to eq player1
        expect(result.opponent_player).to be_nil
        expect(result.rank_requested).to be_nil
        expect(result.cards_received_opponent).to be_empty
        expect(result.card_received_deck).to be_nil
        expect(result.was_book_made).to eq false
        expect(result.go_again?).to eq false
      end
    end

    context 'deck has cards' do
      before do
        game.deck.cards = [card_taken, other_card]
      end

      it 'removes the card from the top of the deck' do
        game.request_deck_card
        expect(game.deck.cards).to_not include card_taken
        expect(game.deck.cards).to include other_card
      end

      it 'gives the card to the player' do
        game.request_deck_card
        expect(player1.cards).to include card_taken
        expect(player1.cards).to_not include other_card
      end

      it 'returns the correct turn result' do
        result = game.request_deck_card
        expect(result.current_player).to eq player1
        expect(result.opponent_player).to be_nil
        expect(result.rank_requested).to be_nil
        expect(result.cards_received_opponent).to be_empty
        expect(result.card_received_deck).to eq card_taken
        expect(result.was_book_made).to eq false
        expect(result.go_again?).to eq false
      end
    end

    context 'when a different player requests a card' do
      before do
        game.deck.cards = [card_taken, other_card]
        game.current_player_index = 1
      end

      it 'removes the card from the top of the deck' do
        game.request_deck_card
        expect(game.deck.cards).to_not include card_taken
        expect(game.deck.cards).to include other_card
      end

      it 'gives the card to the player' do
        game.request_deck_card
        expect(player2.cards).to include card_taken
        expect(player2.cards).to_not include other_card
      end

      it 'returns the correct turn result' do
        result = game.request_deck_card
        expect(result.current_player).to eq player2
        expect(result.opponent_player).to be_nil
        expect(result.rank_requested).to be_nil
        expect(result.cards_received_opponent).to be_empty
        expect(result.card_received_deck).to eq card_taken
        expect(result.was_book_made).to eq false
        expect(result.go_again?).to eq false
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

  describe '#winning_player' do
    let(:player1) {  Player.new('Jeff') }
    let(:player2) {  Player.new('Bob') }
    let(:user3) { Player.new('Billy') }
    let(:players) { [player1, player2, player3] }

    let(:game) { described_class.new(players) }

    context 'when one player has most books' do
      before do
        player1.books = []
        player2.books = [Book.new(5), Book.new(2), Book.new(10)]
        player3.books = [Book.new(12)]
      end

      it 'returns that player' do
        result = game.winning_player

        expect(result).to eq player2
      end
    end

    context 'when there is a tie' do
      before do
        player1.books = [Book.new(8), Book.new(5), Book.new(2)]
        player2.books = [Book.new(5), Book.new(3), Book.new(4)]
        player3.books = [Book.new(15)]
      end

      it 'returns user with most book and highest value book' do
        result = game.winning_player
        expect(result).to eq player1
      end
    end
  end
end
