require_relative '../room'
require_relative 'game'
require_relative '../input'

class GoFishRoom < Room
  attr_accessor :has_shown_round, :inputs, :winner

  def initialize(host_user, capacity: host_user.client.desired_player_count, id: '0000')
    super
    @winner = nil
    reset
  end

  def run_started_game
    return if winner

    play_round until game.game_over?
    self.winner = game.winning_player
    print_winner
  end

  def starting_message
    'Go Fish is starting!'
  end

  def play_round
    print_round_start if has_shown_round == true

    if game.current_player.out_of_cards?
      result = game.request_deck_card
      puts_turn_result_to_all_clients(result)
      switch_turn if result.card_received_deck.nil?
    end

    # get ranks
    collect_rank unless inputs[:rank].value
    return unless inputs[:rank].value

    # collect opponent
    collect_opponent unless inputs[:opponent].value
    return unless inputs[:opponent].value

    result = game.play_turn(rank: inputs[:rank].value, opponent: inputs[:opponent].value.player)
    puts_turn_result_to_all_clients(result)
  end

  def new_game
    Game.new(users.map(&:player))
  end

  private

  def switch_turn
    game.switch_turn
    reset
  end

  def puts_turn_result_to_all_clients(turn_result)
    users.each do |user|
      user.client.puts_socket(turn_result.message(user.player))
    end
  end

  def reset
    @has_shown_round = false
    @inputs = {
      rank: Input.new,
      opponent: Input.new
    }
  end

  def current_user
    player_to_user(game.current_player)
  end

  def current_client
    current_user.client
  end

  def player_to_user(player)
    users[users.index { |user| user.player == player }]
  end

  def print_round_start
    show_cards
    show_whose_turn
    self.has_shown_round = true
  end

  def print_winner
    users.each do |user|
      if user.player == winner
        user.client.puts_socket('You won!')
      else
        user.client.puts_socket("#{winner} won!")
      end
    end
  end

  def show_whose_turn
    users.each do |user|
      if user.player == game.current_player
        user.client.puts_socket('It is your turn')
      else
        user.client.puts_socket("It is #{game.current_player.name}'s turn")
      end
    end
  end

  def show_cards
    users.each do |user|
      user.client.puts_socket(user.player.cards_to_s)
    end
  end

  def collect_rank
    current_client.ask_socket('Enter rank') unless inputs[:rank].sent?
    inputs[:rank].send

    input = current_client.read_socket
    return if input.empty?

    input = input.chomp

    # check if it is valid
    if game.current_player.includes_card_with_rank?(input)
      inputs[:rank].value = input
    else
      current_client.puts_socket('Invalid rank!')
      inputs[:rank].unsend
    end
  end

  def collect_opponent
    unless inputs[:opponent].sent?
      current_client.puts_socket(game.opponent_options_s)
      current_user.client.ask_socket('Enter player id')
    end

    inputs[:opponent].send

    input = current_user.client.read_socket
    return if input.empty?

    input = input.chomp.to_i

    opponent = users[input - 1]

    # check if it is valid
    if opponent.nil? || opponent == current_user
      current_client.puts_socket('Invalid player id!')
      inputs[:opponent].unsend
    elsif opponent.player.out_of_cards?
      current_client.puts_socket('That player is out of cards!')
      inputs[:opponent].unsend
    else
      inputs[:opponent].value = opponent
    end
  end
end
