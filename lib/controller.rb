require_relative 'game'

# manages a single Go Fish game and all humans joined on that game
class Controller
  attr_reader :clients, :messages

  attr_accessor :desired_player_count, :game

  def initialize
    @clients = []
    @messages = {}
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
    desired_player_count && num_players == desired_player_count
  end

  def start_game
    self.game = Game.new
    @clients.each { |client| client.puts_socket('Game is starting...') }
  end

  def run_round
    return unless started?

    puts 'running!'
  end

  private

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
end
