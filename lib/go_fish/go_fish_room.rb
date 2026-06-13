require_relative '../room'
require_relative 'game'

class GoFishRoom < Room
  # other stuff
  #

  private

  # a looping method
  def run_started_game
    raise NotImplementedError('A looping method to run a game')
  end

  def new_game
    Game.new(users)
  end
end
