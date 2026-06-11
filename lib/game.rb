class Game
  SMALL_GAME_CARDS = 7

  attr_reader :players

  def initialize(players)
    @players = players
  end
end
