require_relative '../lib/go_fish/turn_result'
require_relative '../lib/go_fish/player'
require_relative '../lib/card'

# initialize(current_player:, opponent_player: nil, rank_requested: nil,
#                  cards_received_opponent: [], card_received_deck: nil, was_book_made: false)
describe TurnResult do
  describe '#message' do
    let(:current_player_name) { 'Jeff' }
    let(:current_player) { Player.new(current_player_name) }

    let(:opponent_player_name) { 'Bob' }
    let(:opponent_player) { Player.new(opponent_player_name) }

    let(:other_player_name) { 'Henry' }
    let(:other_player) { Player.new(other_player_name) }

    let(:card_received) { Card.new('5', 'Spades') }

    context 'when book_made? true and went_fish? true' do
      let(:turn_result) do
        TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                       card_received_deck: card_received, was_book_made: true)
      end

      it 'contains a book message' do
        result = turn_result.message(other_player)
        expect(result).to match(/book/i)
      end

      it 'shows book rank' do
        result = turn_result.message(other_player)
        expect(result).to match(/#{card_received.rank}/)
      end
    end
  end
end
