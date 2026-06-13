require_relative '../deck'
require_relative '../input'
require_relative 'turn_result'

class Game
  SMALL_GAME_CARDS = 7
  BIG_GAME_CARDS = 5

  attr_reader :players, :deck, :inputs

  attr_accessor :current_player_index, :go_again

  def initialize(players)
    @players = players
    @deck = Deck.new
    @current_player_index = 0
  end

  def game_over?
    book_count == (Card::SUITS * Card::RANKS) / Book::SIZE
  end

  def current_player
    players[current_player_index]
  end

  def start
    deck.shuffle
    if players.length <= 3
      deal_cards_to_players(SMALL_GAME_CARDS)
    else
      deal_cards_to_players(BIG_GAME_CARDS)
    end
  end

  # play_turn (player, rank:, opponent:)
  # play_turn (player, opponent: someone, rank: 'A')
  # TODO: make it return a round result object
  # TODO: make play_turn take parameters for collect_rank and collect_player from room
  def play_turn(rank:, opponent:)
    cards_taken_from_opponent = opponent.take_cards_with_rank(rank)
    turn_result = TurnResult.new(current_player: current_player, opponent_player: opponent, rank_requested: rank,
                                 cards_received_opponent: cards_taken_from_opponent)

    if cards_taken_from_opponent.empty?
      # request_deck_card(rank, turn_result)
    else
      current_player.add_cards(cards_taken_from_opponent)
      book_made = current_player.try_make_book(rank)
      turn_result.was_book_made = true if book_made
    end

    switch_turn unless turn_result.go_again?

    turn_result
  end

  def opponent_options_s
    opponents_with_id_array = []
    players.each_with_index do |player, index|
      next if index == current_player_index

      opponents_with_id_array.push((index + 1).to_s + ': ' + player.name)
    end

    opponents_with_id_array.join(', ')
  end

  private

  def request_deck_card(rank)
    if deck.empty?
      # TODO: deck empty message
    else
      card_taken = deck.take_top_card

      # TODO: grab deck action

      current_player.add_card(card_taken)

      # prevent it from switching turns
      go_again == true if card_taken.rank == rank
    end
  end

  def log_request(rank, opponent)
    current_user.client.puts_socket("You requested a #{rank} from #{opponent.name}")
    all_but_current_user.each do |user|
      if user == opponent
        user.client.puts_socket("#{current_player.name} requested a #{rank} from you")
      else
        user.client.puts_socket("#{current_player.name} requested a #{rank} from #{opponent.name}")
      end
    end
  end

  def log_give(opponent, num_cards_given)
    users.each do |user|
      user.client.puts_socket("#{opponent.name} gave #{num_cards_given} cards to #{current_player.name}")
    end
  end

  def all_but_current_player_names
    all_but_current_client.map(&:name)
  end

  def winning_player
    winning_players = players_with_most_books

    return winning_players[0] if winning_players.length == 1

    player_with_biggest_value_book(winning_players)
  end

  def deal_cards_to_players(num_cards_to_deal)
    num_cards_to_deal.times do
      players.each do |player|
        player.add_card(deck.take_top_card)
      end
    end
  end

  def book_count
    players.inject(0) { |sum, player| sum + player.book_count }
  end

  def players_with_most_books
    players.select { |player| player.book_count == most_books }
  end

  def player_with_biggest_value_book(players_array)
    players_array.max_by(&:biggest_book_value)
  end

  def most_books
    players.max_by(&:book_count).book_count
  end

  def player_go_again
    clients.each(&:reset_variables)
  end

  def switch_turn
    self.current_player_index += 1
    self.current_player_index = 0 if current_player_index >= players.length
  end

  def go_again?
    !!go_again
  end
end
