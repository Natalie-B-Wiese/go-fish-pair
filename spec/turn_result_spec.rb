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

    # current_player:, opponent_player: nil, rank_requested: nil,
    #             cards_received_opponent: [], card_received_deck: nil, was_book_made: false
    context 'when opponent_player is nil, rank_requested is nil, cards_received is nil' do
      let(:turn_result) { TurnResult.new(current_player: current_player) }
      it 'returns player out of game message' do
        result = turn_result.message(current_player)
        expect(result).to match(/#{TurnResult::DISQUALIFIED}/i)
      end

      it 'uses correct subject' do
        result_player = turn_result.message(current_player)
        expect(result_player).to match(/you/i)

        result_opponent = turn_result.message(current_player)
        expect(result_opponent).to match(/#{current_player_name}/i)
      end
    end
  end
end
