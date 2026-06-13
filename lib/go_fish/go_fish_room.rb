require_relative '../room'
require_relative 'game'

class GoFishRoom < Room
  def run_started_game
    play_round until game.game_over?
  end

  def starting_message
    'Go Fish is starting!'
  end

  def play_round
    result = game.play_turn
  end

  def new_game
    Game.new(users)
  end
end
