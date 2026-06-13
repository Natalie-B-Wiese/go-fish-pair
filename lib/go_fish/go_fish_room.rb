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
    show_whose_turn(game.current_player) if round_progress == 0
    result = game.play_turn
  end

  def new_game
    Game.new(users)
  end

  private

  def show_whose_turn(current_player)
    users.each do |user|
      if user.player == current_player
        user.client.puts_socket('It is your turn')
      else
        user.client.puts_socket("It is #{current_player.name}'s turn")
      end
    end

    self.round_progress += 1
  end
end
