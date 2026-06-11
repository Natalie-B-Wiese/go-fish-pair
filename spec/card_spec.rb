require_relative '../lib/card'

describe Card do
  describe '#initialize' do
    it 'has a rank and suit' do
      card = Card.new('A', 'Spades')
      expect(card.rank).to eq 'A'
      expect(card.suit).to eq 'Spades'
    end

    it 'should allow valid ranks' do
      expect do
        Card.new('15', 'Spades')
      end.to raise_error Card::InvalidRank
    end

    it 'should allow valid suits' do
      expect do
        Card.new('2', 'Minecraft')
      end.to raise_error Card::InvalidSuit
    end
  end

  describe '#==' do
    it 'cards of the same rank and suit are equal' do
      card1 = Card.new('A', 'Spades')
      card2 = Card.new('K', 'Spades')
      card3 = Card.new('A', 'Spades')

      expect(card1).not_to eq card2
      expect(card1).to eq card3
    end
  end

  describe '#value' do
    context 'when rank is 2' do
      it 'returns 0' do
        card = Card.new('2', 'Diamonds')
        result = card.value
        expect(result).to eq 0
      end
    end

    context 'when rank is Ace' do
      it 'returns 0' do
        card = Card.new('A', 'Hearts')
        result = card.value
        expect(result).to eq 12
      end
    end
  end

  describe '#to_s' do
    context 'when rank is 2 and suit is Diamonds' do
      it 'returns correct result' do
        card = Card.new('2', 'Diamonds')
        result = card.to_s
        expect(result).to eq '2 of Diamonds'
      end
    end

    context 'when rank is K and suit is Hearts' do
      it 'returns correct result' do
        card = Card.new('K', 'Hearts')
        result = card.to_s
        expect(result).to eq 'K of Hearts'
      end
    end
  end
end
