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

  def add_user(new_user)
    new_user.client.puts_socket("You have joined room #{id}")

    show_current_players_to_new_user(new_user) unless users.empty?
    show_new_user_to_current_players(new_user)

    users.push(new_user)

    show_capacity_message
  end

  def num_players
    users.length
  end

  def host
    users.first
  end

  def full?
    capacity == num_players
  end

  def run_room_if_possible
    # TODO: handle game won
    if started?
      run_started_game
    elsif full?
      start_game
    else
      # room does not have enough players
    end
  end

  private

  def new_game
    raise NotImplementedError('Return a new Game object')
  end

  # a looping method
  def run_started_game
    raise NotImplementedError('A looping method to run a game')
  end

  def start_game
    self.game = new_game
    game.start
  end

  def started?
    !game.nil?
  end

  def puts_to_all_players(message)
    users.each do |user|
      user.client.puts_socket(message)
    end
  end

  def show_current_players_to_new_user(new_user)
    other_player_names = users.map(&:name).join(', ')
    new_user.client.puts_socket("You are playing with #{other_player_names}")
  end

  def show_new_user_to_current_players(new_user)
    puts_to_all_players("#{new_user.name} has joined!")
  end

  def show_capacity_message
    if full?
      puts_to_all_players('All players have joined!')
    else
      puts_to_all_players("Waiting for #{capacity - num_players} more players...")
    end
  end
end
