require_relative 'game'
require_relative 'player'

# manages a single Go Fish game and all humans joined on that game
class Room
  attr_reader :users, :capacity

  attr_accessor :game, :id

  def initialize(host_user, capacity: host_user.client.desired_player_count, id: '0000')
    @capacity = capacity
    @id = id

    @users = []
    @game = nil

    add_user(host_user)
  end

  def add_user(user)
    users.push(user)
    # TODO: show room stuff
  end

  def num_players
    users.length
  end

  def host
    users.first
  end

  def started?
    !game.nil?
  end

  def full?
    capacity == num_players
  end

  def start_game
    self.game = Game.new(users)
    game.start
  end

  def run_round
    return unless started?

    puts 'running!'
  end
end
