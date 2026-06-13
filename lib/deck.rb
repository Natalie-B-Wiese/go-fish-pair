require_relative 'card'

# holds a deck of cards
class Deck
  attr_accessor :cards

  def initialize
    @cards = Card::SUITS.flat_map do |suit|
      Card::RANKS.map do |rank|
        Card.new(rank, suit)
      end
    end
  end

  def cards_left
    cards.length
  end

  def empty?
    cards.empty?
  end

  def take_top_card
    cards.shift
  end

  def shuffle
    shuffled = cards.shuffle
    shuffled = cards.shuffle while shuffled == cards

    self.cards = shuffled
  end
end
