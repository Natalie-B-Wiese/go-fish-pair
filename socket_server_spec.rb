require 'socket'
require_relative '../lib/client_message'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'

describe SocketServer do
  def create_and_accept_client(name)
    client = MockSocketClient.new(SocketServer::PORT, name)
    @clients.push(client)
    @server.accept_new_client(name)
  end

  def create_and_accept_clients(names)
    names.each { |name| create_and_accept_client(name) }
  end

  def all_clients_provide_input(input)
    @clients.each { |client| client.provide_input(input) }
  end

  def all_clients_clear_output
    @clients.each(&:capture_output)
  end

  def create_and_start_game
    num_games = @server.games.length
    @server.create_game_if_possible

    # force the game to be created, even if it initially fails
    while num_games == @server.games.length
      print 'Game nil. Trying again.'
      sleep(1)
      @server.create_game_if_possible
    end

    game = @server.games[-1]
    game.start

    game
  end

  before(:each) do
    @clients = []
    @server = SocketServer.new
    @server.start
    sleep 0.1 # Ensure server is ready for clients
  end

  after(:each) do
    @server.stop
    @clients.each do |client|
      client.close
    end
  end

  it 'is not listening on a port before it is started' do
    @server.stop
    expect { MockSocketClient.new(SocketServer::PORT, 'Player 1') }.to raise_error(Errno::ECONNREFUSED)
  end

  xdescribe '#accept_new_client' do
    context 'when clients join' do
      let(:player1_name) { 'Jeff' }
      let(:player2_name) { 'Bob' }

      it 'new clients get a welcome message' do
        create_and_accept_client(player1_name)
        expect(@clients[0].capture_output).to match(/welcome/i)
      end

      it 'other clients are notified about new player' do
        create_and_accept_client(player1_name)
        all_clients_clear_output
        create_and_accept_client(player2_name)
        expect(@clients[0].capture_output.chomp).to eq "#{player2_name} joined the game!"
      end

      it 'new client sees list of other players' do
        create_and_accept_client(player1_name)
        all_clients_clear_output
        create_and_accept_client(player2_name)

        expect(@clients[1].capture_output.chomp).to match(/#{player1_name}/)
      end
    end
  end

  xdescribe '#create_game_if_possible' do
    let(:player1_name) { 'Jeff' }
    let(:player2_name) { 'Bob' }

    context '1 player' do
      before do
        create_and_accept_client(player1_name)
      end

      it 'does not provide ready prompt' do
        @server.create_game_if_possible
        expect(@clients[0].capture_output).to_not match(/ready/i)
      end

      context 'when ready' do
        it 'does not create a game' do
          @clients[0].provide_input('I am sooooo ready')

          @server.create_game_if_possible
          expect(@server.games.count).to be 0
        end
      end
    end

    context '2+ players' do
      before do
        create_and_accept_client(player1_name)
        create_and_accept_client(player2_name)
      end

      it 'shows ready prompt to all players' do
        @server.create_game_if_possible
        expect(@clients[0].capture_output).to match(/ready/i)
        expect(@clients[1].capture_output).to match(/ready/i)
      end

      it 'ready prompt happens only once' do
        @server.create_game_if_possible
        all_clients_clear_output

        @server.create_game_if_possible
        expect(@clients[0].capture_output).to be_empty
        expect(@clients[1].capture_output).to be_empty
      end

      context '0 ready' do
        it 'does not show starting message' do
          @server.create_game_if_possible

          expect(@clients[0].capture_output).to_not match(/starting/i)
          expect(@clients[1].capture_output).to_not match(/starting/i)
        end

        it 'does not create a game' do
          @server.create_game_if_possible
          expect(@server.games.count).to be 0
        end
      end

      context '1 ready' do
        it 'does not show starting message' do
          @server.create_game_if_possible

          expect(@clients[0].capture_output).to_not match(/starting/i)
          expect(@clients[1].capture_output).to_not match(/starting/i)
        end

        it 'does not create a game' do
          @clients[0].provide_input('I am sooooo ready')
          @server.create_game_if_possible
          expect(@server.games.count).to be 0
        end
      end

      context 'all ready' do
        it 'shows starting message to all players' do
          all_clients_clear_output
          all_clients_provide_input('\n')
          @server.create_game_if_possible

          expect(@clients[0].capture_output).to match(/starting/i)
          expect(@clients[1].capture_output).to match(/starting/i)
        end

        it 'creates a game' do
          @clients[0].provide_input('I am sooooo ready')
          @server.create_game_if_possible
          @clients[1].provide_input('Ready')
          @server.create_game_if_possible
          expect(@server.games.count).to eq 1
        end

        it 'returns a game' do
          all_clients_provide_input('ready')
          result = @server.create_game_if_possible
          expect(result).to be_a(Game)
        end
      end
    end
  end

  describe '#play_turn' do
    let(:player1_name) { 'Jeff' }
    let(:player2_name) { 'Henry' }
    let(:player3_name) { 'Billy' }

    let(:client1) { @clients[0] }
    let(:client2) { @clients[1] }
    let(:client3) { @clients[2] }

    let(:client1_ranks) { @server.clients[0].player.cards.map(&:rank).join(' ') }
    let(:client2_ranks) { @server.clients[1].player.cards.map(&:rank).join(' ') }
    let(:client3_ranks) { @server.clients[2].player.cards.map(&:rank).join(' ') }

    before do
      create_and_accept_clients([player1_name, player2_name, player3_name])
      all_clients_provide_input('Ready')
      game = create_and_start_game

      all_clients_clear_output

      game.play_turn
    end

    context 'for all players' do
      it 'shows their card ranks' do
        result1 = client1.capture_output
        expect(result1).to match(/#{client1_ranks}/)

        result2 = client2.capture_output
        expect(result2).to match(/#{client2_ranks}/)

        result3 = client3.capture_output
        expect(result3).to match(/#{client3_ranks}/)
      end

      it 'shows turn info only once' do
        all_clients_clear_output

        @server.games[0].play_turn

        expect(client1.capture_output).to_not match(/turn/)
        expect(client2.capture_output).to_not match(/turn/)
        expect(client3.capture_output).to_not match(/turn/)
      end

      it 'shows cards only once' do
        all_clients_clear_output

        @server.games[0].play_turn

        expect(client1.capture_output).to_not match(/#{client1_ranks}/)
        expect(client2.capture_output).to_not match(/#{client2_ranks}/)
        expect(client3.capture_output).to_not match(/#{client3_ranks}/)
      end
    end

    context 'on current player' do
      it 'prints It is your turn' do
        result = client1.capture_output
        expect(result).to match(/It is your turn/i)
      end

      it 'does not print It is player_name\'s turn' do
        result = client1.capture_output
        expect(result).to_not match(/It is #{player1_name}'s turn/)
      end

      it 'asks for rank' do
        result = client1.capture_output
        expect(result).to match(/Enter rank/i)
      end

      it 'rank is case insensitive' do
        @server.clients[0].player.add_card(Card.new('A', 'Spades'))

        client1.capture_output
        client1.provide_input('a')
        @server.games[0].play_turn

        result = client1.capture_output
        expect(result).to match(/Enter player/i)
      end

      context 'invalid rank entered' do
        before do
          client1.capture_output
          invalid_rank = 'banana'
          client1.provide_input(invalid_rank)

          @server.games[0].play_turn
        end

        it 'prints invalid rank' do
          result = client1.capture_output
          expect(result).to match(/Invalid rank/i)
        end

        it 'does not show list of players' do
          result = client1.capture_output
          expect(result).to_not match(/#{player2_name}, #{player3_name}/)
        end
      end

      context 'after getting valid rank' do
        before do
          client1.capture_output
          valid_rank = @server.clients[0].player.cards[0].rank

          # give player2 that card
          @server.clients[1].player.add_card(Card.new(valid_rank, 'Spades'))

          # make sure player3 does not have that card
          @server.clients[2].player.take_cards_with_rank(valid_rank)

          client1.provide_input(valid_rank)

          @server.games[0].play_turn
        end

        it 'shows list of players excluding self' do
          result = client1.capture_output
          expect(result).to match(/#{player2_name}, #{player3_name}/)
        end

        it 'asks for player' do
          result = client1.capture_output
          expect(result).to match(/Enter player/i)
        end

        context 'when invalid player' do
          before do
            invalid_name = player1_name
            client1.provide_input(invalid_name)
            @server.games[0].play_turn
          end

          it 'prints invalid player' do
            result = client1.capture_output
            expect(result).to match(/Invalid player/i)
          end
        end

        context 'when valid player' do
          context 'when opponent has card' do
            before do
              client1.provide_input(player2_name)
              @server.games[0].play_turn
            end

            it 'shows give result to all players' do
              expect(client1.capture_output).to match(/#{player2_name} gave you/)
              expect(client2.capture_output).to match(/You gave #{player1_name}/)
              expect(client3.capture_output).to match(/#{player2_name} gave #{player1_name}/)
            end

            it 'does not print a deck action' do
              expect(client1.capture_output).to_not match(/deck/i)
              expect(client2.capture_output).to_not match(/deck/i)
              expect(client3.capture_output).to_not match(/deck/i)
            end
          end

          context 'when opponent not have card' do
            before do
              client1.provide_input(player3_name)
              @server.games[0].play_turn
            end

            it 'shows did not have result to all players' do
              expect(client1.capture_output).to match(/#{player3_name} did not have/)
              expect(client2.capture_output).to match(/#{player3_name} did not have/)
              expect(client3.capture_output).to match(/You did not have/)
            end

            it 'prints a deck action' do
              expect(client1.capture_output).to match(/deck/i)
              expect(client2.capture_output).to match(/deck/i)
              expect(client3.capture_output).to match(/deck/i)
            end
          end

          context 'other time' do
            before do
              client1.provide_input(player2_name)
              @server.games[0].play_turn
            end

            it 'prints request result to all players' do
              expect(client1.capture_output).to match(/You requested/)
              expect(client2.capture_output).to match(/#{player1_name} requested/)
              expect(client3.capture_output).to match(/#{player1_name} requested/)
            end

            it 'shows hands after every turn' do
              client1.capture_output
              client2.capture_output
              client3.capture_output
              @server.games[0].play_turn

              client1_ranks = @server.clients[0].player.cards.map(&:rank).join(' ')
              client2_ranks = @server.clients[1].player.cards.map(&:rank).join(' ')
              client3_ranks = @server.clients[2].player.cards.map(&:rank).join(' ')
              result1 = client1.capture_output
              expect(result1).to match(/#{client1_ranks}/)

              result2 = client2.capture_output
              expect(result2).to match(/#{client2_ranks}/)

              result3 = client3.capture_output
              expect(result3).to match(/#{client3_ranks}/)
            end

            it 'resets message variables after a turn' do
              client1.capture_output
              client2.capture_output
              client3.capture_output
              @server.games[0].play_turn

              expect(client1.capture_output).to_not match(/You requested/)
              expect(client2.capture_output).to_not match(/#{player1_name} requested/)
              expect(client3.capture_output).to_not match(/#{player1_name} requested/)
            end
          end
        end
      end
    end

    # it prints the player's turn to all players
    context 'for other players' do
      it "prints it is player_name's turn" do
        result1 = client2.capture_output
        expect(result1).to match(/It is #{player1_name}'s turn/)

        result2 = client3.capture_output
        expect(result2).to match(/It is #{player1_name}'s turn/)
      end
    end

    context 'when player gets card' do
      let(:valid_rank) { 'A' }

      before do
        client1.capture_output

        # make sure player1 only has one of those cards
        card = Card.new(valid_rank, 'Clubs')
        @server.clients[0].player.cards = []
        @server.clients[0].player.add_card(card)

        # give player2 3 of those cards
        @server.clients[1].player.add_card(Card.new(valid_rank, 'Spades'))
        @server.clients[1].player.add_card(Card.new(valid_rank, 'Hearts'))
        @server.clients[1].player.add_card(Card.new(valid_rank, 'Diamonds'))

        # make sure player3 does not have that card
        @server.clients[2].player.take_cards_with_rank(valid_rank)

        client1.provide_input(valid_rank)
        @server.games[0].play_turn

        client1.capture_output
        client2.capture_output
        client3.capture_output
      end

      it 'prints go again message to all players' do
        client1.provide_input(player2_name)
        @server.games[0].play_turn

        expect(client1.capture_output).to match(/again/i)
        expect(client2.capture_output).to match(/again/i)
        expect(client3.capture_output).to match(/again/i)
      end

      it 'shows hands again' do
        client1.provide_input(player2_name)
        @server.games[0].play_turn

        client1.capture_output
        client2.capture_output
        client3.capture_output
        @server.games[0].play_turn

        client1_ranks = @server.clients[0].player.cards.map(&:rank).join(' ')
        client2_ranks = @server.clients[1].player.cards.map(&:rank).join(' ')
        client3_ranks = @server.clients[2].player.cards.map(&:rank).join(' ')
        result1 = client1.capture_output
        expect(result1).to match(/#{client1_ranks}/)

        result2 = client2.capture_output
        expect(result2).to match(/#{client2_ranks}/)

        result3 = client3.capture_output
        expect(result3).to match(/#{client3_ranks}/)
      end

      context 'when book possible' do
        before do
          client1.capture_output
          client2.capture_output
          client3.capture_output

          client1.provide_input(player2_name)
          @server.games[0].play_turn
        end

        it 'creates a book' do
          expect(@server.clients[0].player.book_count).to eq 1
        end

        it 'displays a message a book was made to all players' do
          expect(client1.capture_output).to match(/book/i)
          expect(client2.capture_output).to match(/book/i)
          expect(client3.capture_output).to match(/book/i)
        end
      end

      context 'when book impossible' do
        before do
          client1.capture_output
          client2.capture_output
          client3.capture_output

          client1.provide_input(player3_name)
          @server.games[0].play_turn
        end

        it 'does not create a book' do
          expect(@server.clients[0].player.book_count).to eq 0
        end

        it 'does not display a book message' do
          expect(client1.capture_output).to_not match(/book/i)
          expect(client2.capture_output).to_not match(/book/i)
          expect(client3.capture_output).to_not match(/book/i)
        end
      end
    end

    # this rank is validated to belong to the player
    # once validated, it asks the player to choose who to ask it from
    # This name must be validated to be a player and to not be self
    # Once everything is validated, the request is made
    # All clients receive a puts about this request (Turn_Info)
  end
end
