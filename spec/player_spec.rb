require_relative '../lib/go_fish/player'
require_relative '../lib/card'

describe Player do
  describe '#add_card' do
    it 'adds a card to the hand' do
      player = Player.new('Natalie')
      card1 = Card.new('3', 'Diamonds')

      player.add_card(card1)
      expect(player.cards).to include(card1)
    end
  end

  describe '#add_cards' do
    it 'adds multiple cards' do
      player = Player.new('Natalie')
      card1 = Card.new('3', 'Diamonds')
      card2 = Card.new('5', 'Hearts')

      player.add_cards([card1, card2])
      expect(player.cards).to include(card1)
      expect(player.cards).to include(card2)
    end
  end

  describe '#take_cards_with_rank' do
    let(:player) { described_class.new('Natalie') }
    let(:card1) { Card.new('A', 'Diamonds') }
    let(:card2) { Card.new('2', 'Diamonds') }
    let(:card3) { Card.new('3', 'Diamonds') }

    let(:card2_same) { Card.new('2', 'Hearts') }

    before do
      player.add_cards([card1, card2, card3, card2_same])
    end

    context 'when player has one of the specified card' do
      let(:card_to_take) { card3 }
      it 'returns an array with a single card' do
        result = player.take_cards_with_rank(card_to_take.rank)
        expect(result).to eq [card_to_take]
      end

      it 'removes the card from the player' do
        player.take_cards_with_rank(card_to_take.rank)
        expect(player.cards).to_not include(card_to_take)
      end

      it 'works with non numerical cards' do
        result = player.take_cards_with_rank(card1.rank)
        expect(result).to eq [card1]
        expect(player.cards).to_not include(card1)
      end
    end

    context 'when player has more than one of the specified card' do
      it 'returns an array with all cards' do
        result = player.take_cards_with_rank('2')
        expect(result).to include(card2, card2_same)
      end

      it 'removes all the matching rank cards from the player' do
        player.take_cards_with_rank('2')
        expect(player.cards).to_not include(card2, card2_same)
      end
    end

    context 'when player does not have the specified card' do
      let(:nonexistant_rank) { 'K' }
      it 'returns empty array' do
        result = player.take_cards_with_rank(nonexistant_rank)
        expect(result).to be_empty
      end

      it 'does not remove any cards from player' do
        num_cards_before = player.cards.length
        player.take_cards_with_rank(nonexistant_rank)
        expect(player.cards.length).to eq num_cards_before
      end
    end
  end

  describe '#card_count' do
    context 'when the player has no cards' do
      it 'returns 0' do
        player = Player.new('Natalie')
        result = player.card_count
        expect(result).to eq 0
      end
    end

    context 'when there is 1 card' do
      it 'returns 1' do
        player = Player.new('Natalie')
        player.add_card(Card.new('A', 'Spades'))

        result = player.card_count
        expect(result).to eq 1
      end
    end

    context 'when there are many cards' do
      it 'returns correct number' do
        player = Player.new('Natalie')
        player.add_card(Card.new('A', 'Spades'))
        player.add_card(Card.new('J', 'Diamonds'))
        player.add_card(Card.new('3', 'Hearts'))

        result = player.card_count
        expect(result).to eq 3
      end
    end
  end

  describe '#out_of_cards?' do
    let(:player) { Player.new('Natalie') }

    it 'returns true when player has no cards' do
      expect(player).to be_out_of_cards
    end

    it 'returns false when player has cards' do
      player.add_card(Card.new('A', 'Spades'))
      expect(player).to_not be_out_of_cards
    end
  end

  describe '#try_make_book' do
    let(:player) { Player.new('Natalie') }
    let(:possible_rank) { 'A' }
    let(:impossible_rank) { '5' }

    before do
      player.add_card(Card.new(possible_rank, 'Hearts'))
      player.add_card(Card.new(possible_rank, 'Spades'))
      player.add_card(Card.new(possible_rank, 'Clubs'))
      player.add_card(Card.new(possible_rank, 'Diamonds'))

      player.add_card(Card.new(impossible_rank, 'Hearts'))
      player.add_card(Card.new(impossible_rank, 'Spades'))
      player.add_card(Card.new(impossible_rank, 'Clubs'))
    end

    context 'when book possible' do
      it 'removes those cards from player' do
        card_count_before = player.cards.length

        player.try_make_book(possible_rank)
        expect(player.cards.length).to eq card_count_before - Book::SIZE
        expect(player.includes_card_with_rank?(possible_rank)).to be false
      end

      it 'adds the book to books array' do
        value = Card.rank_to_value(possible_rank)
        player.try_make_book(possible_rank)
        expect(player.book_count).to eq 1
        expect(player.books[0].value).to eq value
      end

      it 'returns the book' do
        result = player.try_make_book(possible_rank)
        expect(result).not_to be_nil
      end
    end

    context 'when book impossible' do
      it 'returns nil' do
        result = player.try_make_book(impossible_rank)
        expect(result).to be_nil
      end

      it 'does not remove cards' do
        card_count_before = player.cards.length

        player.try_make_book(impossible_rank)
        expect(player.cards.length).to eq card_count_before
        expect(player.includes_card_with_rank?(possible_rank)).to be true
      end

      it 'does not add a book to array' do
        player.try_make_book(impossible_rank)
        expect(player.book_count).to eq 0
      end
    end
  end

  describe '#cards_to_s' do
    let(:player) { Player.new('Natalie') }

    context 'when hand is empty' do
      it 'shows empty cards message' do
        expect(player.cards_to_s).to match(/no cards/i)
      end
    end

    context 'when hand has 1 card' do
      before do
        player.add_card(Card.new('5', 'Diamonds'))
      end
      it 'shows card' do
        result = player.cards_to_s
        expect(result).to eq '5 of Diamonds'
      end
    end

    context 'when hand has multiple cards' do
      before do
        player.add_card(Card.new('5', 'Diamonds'))
        player.add_card(Card.new('3', 'Hearts'))
      end
      it 'shows cards seperated by commas' do
        result = player.cards_to_s
        expect(result).to eq '5 of Diamonds, 3 of Hearts'
      end
    end
  end
end
