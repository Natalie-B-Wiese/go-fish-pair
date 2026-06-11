require 'socket'
require_relative 'input'

# an object that can read and write to client's terminal
class Client
  attr_reader :socket, :inputs

  INPUT_SYMBOL = '->'.freeze

  def initialize(socket)
    @socket = socket

    @inputs = {
      name: Input.new,
      join_or_create: Input.new,

      room_id: Input.new,
      desired_player_count: Input.new
    }
  end

  def host?
    @inputs[:join_or_create].value == 'create'
  end

  def desired_player_count
    @inputs[:desired_player_count].value
  end

  def desired_room_id
    @inputs[:room_id].value
  end

  def name
    @inputs[:name].value
  end

  def read_socket
    socket.read_nonblock(1000)
  rescue IO::WaitReadable
    ''
  end

  def puts_socket(message)
    socket.puts(message)
  end

  def ask_socket(message)
    puts_socket(message + INPUT_SYMBOL)
  end

  def ready?(open_room_ids)
    collect_name unless inputs[:name].value
    return false unless inputs[:name].value

    collect_join_type unless inputs[:join_or_create].value
    return false unless inputs[:join_or_create].value

    ready_to_be_added_to_room?(open_room_ids)
  end

  private

  def ready_to_be_added_to_room?(open_room_ids)
    if host?
      ready_to_create_room?
    else
      ready_to_join_room?(open_room_ids)
    end
  end

  def ready_to_create_room?
    collect_player_count unless inputs[:desired_player_count].value
    !!inputs[:desired_player_count].value
  end

  def ready_to_join_room?(open_room_ids)
    collect_room_id(open_room_ids) unless inputs[:room_id].value
    !!inputs[:room_id].value
  end

  def collect_name
    ask_socket('Enter name') unless inputs[:name].sent?
    inputs[:name].send

    input = read_socket
    return if input.empty?

    validate_name(input.chomp.strip)
  end

  def validate_name(name)
    if valid_name?(name)
      inputs[:name].value = name
    else
      puts_socket('Invalid name!')
      inputs[:name].unsend
    end
  end

  def valid_name?(name)
    !name.empty?
  end

  def collect_join_type
    ask_socket('CREATE or JOIN a room?') unless inputs[:join_or_create].sent?
    inputs[:join_or_create].send

    input = read_socket
    return if input.empty?

    validate_join_type(input.chomp.downcase)
  end

  def validate_join_type(choice)
    if %w[create join].include?(choice)
      inputs[:join_or_create].value = choice
    else
      puts_socket('Invalid choice!')
      inputs[:join_or_create].unsend
    end
  end

  def collect_player_count
    ask_socket('Enter number of players') unless inputs[:desired_player_count].sent?
    inputs[:desired_player_count].send

    input = read_socket
    return if input.empty?

    validate_player_count(input.chomp.to_i)
  end

  def validate_player_count(number)
    if valid_player_count?(number)
      inputs[:desired_player_count].value = number
    else
      puts_socket('Invalid input!')
      inputs[:desired_player_count].unsend
    end
  end

  def valid_player_count?(number)
    number.positive?
  end

  def collect_room_id(open_room_ids)
    ask_socket('Enter room code') unless inputs[:room_id].sent?
    inputs[:room_id].send

    input = read_socket
    return if input.empty?

    validate_room_id(input.chomp, open_room_ids)
  end

  def validate_room_id(room_id, open_room_ids)
    if open_room_ids.include?(room_id)
      inputs[:room_id].value = room_id
    else
      puts_socket('Invalid room code!')
      inputs[:room_id].unsend
    end
  end
end
