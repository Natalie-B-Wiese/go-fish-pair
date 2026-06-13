require_relative '../room'
require_relative 'game'
require_relative '../input'

class GoFishRoom < Room
  attr_accessor :round_progress, :inputs

  def initialize(host_user, capacity: host_user.client.desired_player_count, id: '0000')
    super
    reset
  end

  def run_started_game
    play_round until game.game_over?
  end

  def starting_message
    'Go Fish is starting!'
  end

  def play_round
    print_round_start if round_progress == 0

    # get ranks
    collect_rank unless inputs[:rank].value
    return unless inputs[:rank].value

    result = game.play_turn
  end

  def new_game
    Game.new(users)
  end

  private

  def reset
    @round_progress = 0
    @inputs = {
      rank: Input.new
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
    self.round_progress += 1
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
end
