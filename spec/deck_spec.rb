require_relative '../lib/deck'
require_relative '../lib/card'

describe Deck do
  it 'Should have 52 cards when created' do
    deck = Deck.new
    expect(deck.cards_left).to eq 52
  end

  describe '#take_top_card' do
    it 'returns the top card' do
      deck = Deck.new
      card = deck.take_top_card
      expect(card).to_not be_nil
      expect(card).to be_a Card
      expect(card).to respond_to(:rank)
    end

    it 'gives a unique card each time' do
      deck = Deck.new
      card1 = deck.take_top_card
      card2 = deck.take_top_card
      expect(card1).not_to eq card2
    end
  end

  describe '#cards_left' do
    it 'returns 52 on full deck' do
      deck = Deck.new
      expect(deck.cards_left).to eq 52
    end
    it 'returns cards_left for non-full deck' do
      deck = Deck.new
      deck.take_top_card
      deck.take_top_card
      deck.take_top_card
      expect(deck.cards_left).to eq 49
    end
  end

  describe '#empty?' do
    it 'returns false when there are cards' do
      deck = Deck.new
      expect(deck).to_not be_empty
    end

    it 'returns true when there are no cards left' do
      deck = Deck.new

      # clear all the cards
      deck.cards = []

      expect(deck).to be_empty
    end
  end

  describe '#shuffle' do
    it 'shuffles the array' do
      non_shuffled = Deck.new
      shuffled = Deck.new
      shuffled.shuffle

      expect(non_shuffled.cards).not_to eq shuffled.cards
    end
  end
end
