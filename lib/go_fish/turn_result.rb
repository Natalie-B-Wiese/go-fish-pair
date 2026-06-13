class TurnResult
  attr_reader :current_player, :opponent_player, :rank_requested, :cards_received_opponent, :card_received_deck

  attr_accessor :was_book_made

  def initialize(current_player:, opponent_player: nil, rank_requested: nil,
                 cards_received_opponent: [], card_received_deck: nil, was_book_made: false)
    @current_player = current_player
    @opponent_player = opponent_player
    @rank_requested = rank_requested
    @cards_received_opponent = cards_received_opponent
    @card_received_deck = card_received_deck
    @was_book_made = was_book_made
  end

  def message(player)
    if book_made?
      book_message(player)
    else
      puts 'other'
    end
  end

  def go_again?
    rank_received == rank_requested || was_book_made == true
  end

  private

  # TODO: handle if deck is empty
  def rank_received
    if went_fish? && card_received_deck
      card_received_deck.rank
    elsif !cards_received_opponent.empty?
      cards_received_opponent.first.rank
    else
      nil
    end
  end

  def book_message(player)
    "#{player_to_s(player)} made a book with four #{rank_received}s!"
  end

  def book_made?
    !!was_book_made
  end

  def went_fish?
    cards_received_opponent.empty?
  end

  def opponent_to_s(you_player, is_subject = true)
    player_variable_to_s(opponent_player, you_player, is_subject)
  end

  def player_to_s(you_player, is_subject = true)
    player_variable_to_s(current_player, you_player, is_subject)
  end

  def player_variable_to_s(variable_player, you_player, is_subject)
    you = 'You'
    you = you.downcase unless is_subject
    variable_player == you_player ? you : variable_player.name
  end
end
