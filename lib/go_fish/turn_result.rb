class TurnResult
  NO_CARDS = 'ran out of cards'
  EMPTY_DECK = 'the deck is empty'
  GO_AGAIN = 'can go again'
  BOOK = 'made a book with four'
  DISQUALIFIED = 'out of the game'

  attr_reader :current_player, :opponent_player, :rank_requested, :cards_received_opponent

  attr_accessor :was_book_made, :card_received_deck

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
    if player_out_of_cards?
      out_of_cards_message(player)
    else
      string = request_message(player) + give_message(player)
      string += draw_deck_message(player) if cards_received_opponent.nil?
      string += book_message(player) if book_made?
      string += "#{player_to_s(player)} #{GO_AGAIN}." if go_again?
      string
    end
  end

  def go_again?
    (!rank_received.nil? && rank_received == rank_requested) || was_book_made == true
  end

  def rank_received
    if went_fish? && card_received_deck
      card_received_deck.rank
    elsif !cards_received_opponent.empty?
      cards_received_opponent.first.rank
    else
      nil
    end
  end

  private

  def out_of_cards_message(player)
    if card_received_deck.nil?
      out_of_game_message(player)
    else
      "#{player_to_s(player)} #{NO_CARDS}. #{draw_deck_message(player)}."
    end
  end

  def player_out_of_cards?
    opponent_player.nil?
  end

  def request_message(player)
    "#{player_to_s(player)} requested a #{rank_requested} from #{opponent_to_s(player, false)}."
  end

  def give_message(player)
    card_word = 'card'
    card_word += 's' unless cards_received_opponent.length == 1
    "#{opponent_to_s(player)} gave #{cards_received_opponent.length} #{card_word} to #{player_to_s(player, false)}."
  end

  def draw_deck_message(player)
    if card_received_deck.nil?
      "#{current_player.name} tried to fish, but #{EMPTY_DECK}."
    elsif player == current_player
      "You drew a #{card_received_deck} from the deck."
    else
      "#{current_player.name} drew a card from the deck."
    end
  end

  def book_message(player)
    "#{player_to_s(player)} #{BOOK} #{rank_received}s!"
  end

  def out_of_game_message(player)
    "#{player_to_s(player)} #{NO_CARDS} and #{EMPTY_DECK}. " +
      "#{player_to_s(player)} #{is_are(current_player, player)} #{DISQUALIFIED}."
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

  def is_are(variable_player, you_player)
    you_player == variable_player ? 'are' : 'is'
  end

  def player_variable_to_s(variable_player, you_player, is_subject)
    you = 'You'
    you = you.downcase unless is_subject
    variable_player == you_player ? you : variable_player.name
  end
end
