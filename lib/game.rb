require_relative 'deck'

class Game
  SMALL_GAME_CARDS = 7
  BIG_GAME_CARDS = 5

  attr_reader :users, :deck

  attr_accessor :current_player_index

  def initialize(users)
    @users = users
    @deck = Deck.new
    @current_player_index = 0
  end

  def clients
    @users.map(&:client)
  end

  def players
    @users.map(&:player)
  end

  def start
    deck.shuffle
    if users.length <= 3
      deal_cards_to_players(SMALL_GAME_CARDS)
    else
      deal_cards_to_players(BIG_GAME_CARDS)
    end
  end

  private

  def deal_cards_to_players(num_cards_to_deal)
    num_cards_to_deal.times do
      players.each do |player|
        player.add_card(deck.take_top_card)
      end
    end
  end
end
