require 'socket'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'
require_relative '../lib/client'

describe SocketServer do
  let!(:server) { SocketServer.new }

  before(:each) do
    server.start
    sleep 0.1 # Ensure server is ready for clients
  end

  after(:each) do
    server.stop
  end

  def create_and_accept_new_client
    client = MockSocketClient.new
    server.accept_new_client
    client
  end

  def question_regex(regex)
    Regexp.new(regex.source + /(\s*\S*)*#{Client::INPUT_SYMBOL}/.source)
  end

  it 'is not listening on a port before it is started' do
    server.stop
    expect { MockSocketClient.new }.to raise_error(Errno::ECONNREFUSED)
  end

  describe '#accept_new_client' do
    let!(:client1) { create_and_accept_new_client }
    it 'adds client to pending clients array' do
      expect(server.pending_clients.length).to eq 1
    end

    it 'shows welcome message to client' do
      expect(client1.capture_output).to match(/welcome/i)
    end
  end

  describe '#handle_pending_clients' do
    let!(:client1) { create_and_accept_new_client }

    it 'asks the client for a name' do
      server.handle_pending_clients
      expect(client1.capture_output).to match(question_regex(/name/))
    end

    it 'asks only once' do
      server.handle_pending_clients
      client1.capture_output

      expect(client1.capture_output).to_not match(question_regex(/name/))
    end

    context 'empty name provided' do
      before do
        invalid_input = ''
        client1.provide_input(invalid_input)
        server.handle_pending_clients
      end

      it 'shows an error' do
        expect(client1.capture_output).to match(/invalid/i)
      end

      it 'asks again for name on next run' do
        server.handle_pending_clients
        expect(client1.capture_output).to match(question_regex(/name/))
      end
    end

    context 'valid name provided' do
      before do
        valid_input = 'Natalie'
        client1.provide_input(valid_input)
        server.handle_pending_clients
      end

      it 'removes client from pending client' do
        expect(server.pending_clients.length).to eq 0
      end

      it 'creates a pending user' do
        expect(server.pending_users.length).to eq 1
      end
    end
  end
end
