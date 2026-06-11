class Game
  SMALL_GAME_CARDS = 7

  attr_reader :users

  def initialize(users)
    @users = users
  end

  def clients
    @users.map(&:client)
  end

  def players
    @users.map(&:player)
  end
end
