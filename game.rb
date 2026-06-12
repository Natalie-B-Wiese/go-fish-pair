require_relative 'deck'
require_relative 'action_logs/action'
require_relative 'action_logs/request_action'
require_relative 'action_logs/give_action'
require_relative 'action_logs/deck_action'
require_relative 'action_logs/go_again_action'
require_relative 'action_logs/book_action'
require_relative 'action_log'

class Game
  attr_reader :clients, :deck
  attr_accessor :current_player_index, :action_log

  MIN_PLAYERS = 2

  # validate input method.
  # Socket should call it before calling any other game methods (go_fish, request_player_card)
  # That way they don't show errors

  # game collaborates with server
  # Player does not collaborate with server

  def initialize(client_objs)
    @clients = client_objs
    @deck = Deck.new
    @current_player_index = 0
    @action_log = ActionLog.new
  end

  def players
    clients.map(&:player)
  end

  def start
    deck.shuffle
    deal
  end

  def request_deck_card(rank)
    if deck.empty?
      create_deck_action(rank)
    else
      card_taken = deck.take_top_card
      create_deck_action(rank, card_taken.rank)

      current_player.add_card(card_taken)

      # prevent it from switching turns
      return if card_taken.rank == rank
    end

    switch_turn
  end

  # play_turn (player, rank:, opponent:)
  # play_turn (player, opponent: someone, rank: 'A')
  def play_turn
    print_round
    current_client.valid_rank_and_player(self)

    return unless current_client.input_valid?

    opponent_name = current_client.messages[:opponent].value
    rank = current_client.messages[:rank].value

    clients.each(&:reset_variables)

    create_request_action(opponent_name, rank)

    previous_player = current_player
    request_card_from_player(rank, opponent_name)
    return unless current_player == previous_player

    player_go_again(rank)
  end

  # rank and player_name should be validated before this is called
  # This can be private since it is only called by this class
  def request_card_from_player(rank, player_name)
    opponent = find_player_by_name(player_name)
    cards_taken = opponent.take_cards_with_rank(rank)

    create_give_action(opponent, rank, cards_taken.length)

    if cards_taken.empty?
      request_deck_card(rank)
    else
      current_player.add_cards(cards_taken)
    end
  end

  def current_client
    clients[current_player_index]
  end

  def current_player
    players[current_player_index]
  end

  # used by player
  def all_but_current_client
    clients - [current_client]
  end

  def all_but_current_player_names
    all_but_current_client.map(&:name)
  end

  def game_over?
    book_count == (Card::SUITS * Card::RANKS) / Book::SIZE
  end

  def winning_player
    winning_players = players_with_most_books

    return winning_players[0] if winning_players.length == 1

    player_with_biggest_value_book(winning_players)
  end

  private

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

  # the rank is the rank that player successfully received on last turn
  def player_go_again(rank)
    clients.each(&:reset_variables)

    create_book_action(rank) unless current_player.try_make_book(rank).nil?

    create_go_again_action
  end

  def create_request_action(opponent_name, rank)
    action = RequestAction.new(current_player,
                               find_player_by_name(opponent_name),
                               rank)
    action_log.push(action)

    print_log_result
  end

  def create_go_again_action
    action = GoAgainAction.new(current_player)
    action_log.push(action)

    print_log_result
  end

  def create_book_action(rank)
    action = BookAction.new(current_player, rank)
    action_log.push(action)

    print_log_result
  end

  def create_give_action(opponent_player, rank, num_cards_taken)
    # initialize(current_player, opponent_player, rank, num_cards_taken)
    action = GiveAction.new(current_player,
                            opponent_player,
                            rank,
                            num_cards_taken)
    action_log.push(action)

    print_log_result
  end

  # initialize(current_player, rank, rank_taken = nil)
  def create_deck_action(rank, rank_taken = nil)
    action = DeckAction.new(current_player, rank, rank_taken)
    action_log.push(action)

    print_log_result
  end

  def print_log_result
    clients.each do |client|
      client.puts(action_log.most_recent.to_s(client.player))
    end
  end

  def print_round
    clients.each do |client|
      client.try_print_round(current_client)
    end
  end

  def find_player_by_name(name)
    players_with_name = players.select { |player| player.name == name }
    players_with_name[0]
  end

  def switch_turn
    self.current_player_index += 1
    self.current_player_index = 0 if current_player_index >= players.length
  end

  def deal
    cards_per_player = players.length <= 3 ? 7 : 5

    cards_per_player.times do
      players.each_with_index do |_, index|
        players[index].add_card(deck.take_top_card)
      end
    end
  end
end
