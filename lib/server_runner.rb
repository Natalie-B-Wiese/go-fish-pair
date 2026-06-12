require_relative 'socket_server'

server = SocketServer.new
server.start
while true
  begin
    server.accept_new_client
    server.handle_pending_clients
    server.run_games
  rescue StandardError
    server.stop
  end

end
