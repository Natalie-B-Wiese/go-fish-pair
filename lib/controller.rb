class Controller
  attr_reader :clients

  def initialize
    @clients = []
  end

  def add_client(client)
    clients.push(client)
    client.puts_socket 'Welcome to Go Fish!'
  end
end
