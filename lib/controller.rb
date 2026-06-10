class Controller
  attr_reader :clients, :messages

  attr_accessor :desired_player_count

  def initialize
    @clients = []
    @messages = {}
    @desired_player_count = nil
  end

  def add_client(client)
    clients.push(client)
    client.puts_socket 'Welcome to Go Fish!'
  end

  def num_players
    @clients.length
  end

  def ready?
    check_desired_player_count!
    return if desired_player_count.nil? || num_players != desired_player_count

    host.puts_socket('Game is starting...')
  end

  def host
    clients.first
  end

  private

  def check_desired_player_count!
    # Goal: set check_desired_player_count and send message
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
