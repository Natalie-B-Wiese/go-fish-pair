require_relative '../room'
require_relative 'game'

class GoFishRoom < Room
  attr_accessor :round_progress

  def initialize(host_user, capacity: host_user.client.desired_player_count, id: '0000')
    super
    @round_progress = 0
  end

  def run_started_game
    play_round until game.game_over?
  end

  def starting_message
    'Go Fish is starting!'
  end

  def play_round
    print_round_start if round_progress == 0
    result = game.play_turn
  end

  def new_game
    Game.new(users)
  end

  private

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
end
