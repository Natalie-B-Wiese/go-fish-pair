require_relative 'book'

class Player
  attr_reader :name
  attr_accessor :cards, :books

  def initialize(name)
    @name = name
    @cards = []
    @books = []
  end

  def add_card(card)
    @cards.push(card)
  end

  def add_cards(card_array)
    card_array.each { |card| add_card(card) }
  end

  def take_cards_with_rank(rank)
    cards_taken = cards_with_rank(rank)
    self.cards -= cards_taken
    cards_taken
  end

  def card_count
    cards.length
  end

  def book_count
    books.length
  end

  def out_of_cards?
    cards.empty?
  end

  def includes_card_with_rank?(rank)
    !cards_with_rank(rank).empty?
  end

  def cards_to_s
    return 'You have no cards' if cards.empty?

    cards.map(&:to_s).join(', ')
  end

  def biggest_book_value
    value = 0
    books.each do |book|
      value = book.value if value < book.value
    end
    value
  end

  def try_make_book(rank)
    cards_in_book = cards_with_rank(rank)
    return nil unless cards_in_book.length == Book::SIZE

    self.cards -= cards_in_book
    value = Card.rank_to_value(rank)
    book = Book.new(value)
    books.push(book)
    book
  end

  private

  def cards_with_rank(rank)
    cards.select { |card| card.rank == rank }
  end
end
