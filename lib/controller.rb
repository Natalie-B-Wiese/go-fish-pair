require_relative 'game'
require_relative 'player'

# manages a single Go Fish game and all humans joined on that game
class Controller
  attr_reader :clients, :players, :messages, :names_asked, :player_names

  attr_accessor :desired_player_count, :game

  def initialize
    @clients = []
    @players = []

    @messages = {}
    @names_asked = []
    @player_names = []
    @desired_player_count = nil
    @game = nil
  end

  def add_client(client)
    clients.push(client)
    client.puts_socket 'Welcome to Go Fish!'
  end

  def num_players
    @clients.length
  end

  def host
    clients.first
  end

  def started?
    !game.nil?
  end

  def ready?
    collect_player_count
    return false unless desired_player_count

    collect_player_names
    all_players_named?
  end

  def start_game
    create_players
    self.game = Game.new(players)
    @clients.each { |client| client.puts_socket('Game is starting...') }
  end

  def run_round
    return unless started?

    puts 'running!'
  end

  private

  def create_players
    player_names.each do |name|
      players.push(Player.new(name))
    end
  end

  def collect_player_count
    # Goal: set desired_player_count and send message
    # Check if input
    # Check if input is valid
    #
    # Send message

    return desired_player_count unless desired_player_count.nil?

    host.ask_socket('Enter number of players') unless messages[:host]
    messages[:host] = true

    input = host.read_socket
    return if input.empty?

    validate_player_count(input.chomp.to_i)
  end

  def validate_player_count(number)
    if valid_player_count?(number)
      self.desired_player_count = number
    else
      host.puts_socket('Invalid input!')
      messages.delete(:host)
    end
  end

  def valid_player_count?(number)
    number.positive?
  end

  def collect_player_names
    clients.each_with_index do |client, index|
      collect_client_name(client, index)
    end
  end

  def collect_client_name(client, index)
    client.ask_socket('Enter name') unless names_asked[index]
    names_asked[index] = true

    input = client.read_socket
    return if input.empty?

    validate_player_name(input.chomp, client, index)
  end

  def validate_player_name(name, client, client_index)
    if valid_player_name?(name)
      player_names[client_index] = name
    else
      client.puts_socket('Invalid name!')
      names_asked[client_index] = nil
    end
  end

  def valid_player_name?(name)
    !name.empty?
  end

  def all_players_named?
    return false if player_names.length != num_players

    player_names.each do |name|
      return false unless name
    end

    true
  end
end
