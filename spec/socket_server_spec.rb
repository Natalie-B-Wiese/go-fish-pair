require 'socket'
require_relative '../lib/socket_server'
require_relative 'mock_socket_client'

describe SocketServer do
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

  def create_and_accept_new_client
    client = MockSocketClient.new(SocketServer::PORT)
    @clients.push(client)
    @server.accept_new_client
    client
  end

  it 'is not listening on a port before it is started' do
    @server.stop
    expect { MockSocketClient.new(SocketServer::PORT) }.to raise_error(Errno::ECONNREFUSED)
  end

  describe '#accept_new_client' do
    context 'with one client' do
      it 'adds client to array' do
        create_and_accept_new_client
        expect(@server.controller.clients.length).to eq 1
      end

      it 'shows welcome message' do
        client1 = create_and_accept_new_client
        expect(client1.capture_output).to match(/welcome/i)
      end
    end

    context 'with multiple clients' do
      it 'adds client to array' do
        create_and_accept_new_client
        create_and_accept_new_client
        expect(@server.controller.clients.length).to eq 2
      end

      it 'shows welcome message to all clients' do
        client1 = create_and_accept_new_client
        client2 = create_and_accept_new_client
        expect(client1.capture_output).to match(/welcome/i)
        expect(client2.capture_output).to match(/welcome/i)
      end
    end
  end
end
