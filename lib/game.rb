require_relative 'deck'
require_relative 'input'

class Game
  SMALL_GAME_CARDS = 7
  BIG_GAME_CARDS = 5

  attr_reader :users, :deck, :inputs

  attr_accessor :current_player_index

  def initialize(users)
    @users = users
    @deck = Deck.new
    @current_player_index = 0
    @inputs = {
      rank: Input.new,
      player: Input.new
    }
  end

  def clients
    @users.map(&:client)
  end

  def players
    @users.map(&:player)
  end

  def start
    deck.shuffle
    if users.length <= 3
      deal_cards_to_players(SMALL_GAME_CARDS)
    else
      deal_cards_to_players(BIG_GAME_CARDS)
    end

    starting_announcement
  end

  def request_deck_card(rank)
    if deck.empty?
      # create_deck_action(rank)
    else
      card_taken = deck.take_top_card
      # create_deck_action(rank, card_taken.rank)

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

    # get ranks
    collect_rank unless inputs[:rank].value
    return unless inputs[:rank].value

    collect_player unless inputs[:player].value
    return unless inputs[:player].value

    rank = inputs[:rank].value
    opponent = inputs[:player].value

    request_card_from_user(rank, opponent)

    puts 'hi'
    # current_client.valid_rank_and_player(self)

    # return unless current_client.input_valid?

    # opponent_name = current_client.messages[:opponent].value
    # rank = current_client.messages[:rank].value

    # clients.each(&:reset_variables)

    # create_request_action(opponent_name, rank)

    # previous_player = current_player
    # request_card_from_player(rank, opponent_name)
    # return unless current_player == previous_player

    # player_go_again
  end

  # rank and player_name should be validated before this is called
  # This can be private since it is only called by this class
  def request_card_from_user(rank, user)
    log_request(rank, user)
    cards_taken = user.player.take_cards_with_rank(rank)

    if cards_taken.empty?
      request_deck_card(rank)
    else
      current_player.add_cards(cards_taken)
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

  # id is 1-based
  def user_by_id(id)
    users[id - 1]
  end

  def show_opponent_options
    players_with_id = []
    users.each_with_index do |user, index|
      players_with_id.push((index + 1).to_s + ': ' + user.player.name)
    end

    # exclude self from this list
    players_with_id.delete_at(current_player_index)
    current_user.client.puts_socket(players_with_id.join(', '))
  end

  def all_but_current_user
    users - [current_user]
  end

  def collect_rank
    current_user.client.ask_socket('Enter rank') unless inputs[:rank].sent?
    inputs[:rank].send

    input = current_user.client.read_socket
    return if input.empty?

    input = input.chomp

    # check if it is valid
    if current_user.player.includes_card_with_rank?(input)
      inputs[:rank].value = input
    else
      current_user.client.puts_socket('Invalid rank!')
      inputs[:rank].unsend
    end
  end

  def collect_player
    unless inputs[:player].sent?
      show_opponent_options
      current_user.client.ask_socket('Enter player id')
    end

    inputs[:player].send

    input = current_user.client.read_socket
    return if input.empty?

    input = input.chomp.to_i

    opponent = user_by_id(input)

    # check if it is valid
    if opponent && opponent != current_user
      inputs[:player].value = opponent
    else
      current_user.client.puts_socket('Invalid player id!')
      inputs[:player].unsend
    end
  end

  def starting_announcement
    clients.each do |client|
      client.puts_socket('Game is starting!')
    end
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

  def print_round
    show_cards
    show_whose_turn
  end

  def show_cards
    users.each do |user|
      user.client.puts_socket(user.player.cards_to_s)
    end
  end

  def show_whose_turn
    users.each do |user|
      if user == current_user
        user.client.puts_socket('It is your turn')
      else
        user.client.puts_socket("It is #{current_player.name}'s turn")
      end
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

  def current_user
    users[current_player_index]
  end
end
