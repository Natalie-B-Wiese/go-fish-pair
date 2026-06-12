class User
  attr_reader :client, :player

  def initialize(client, player)
    @client = client
    @player = player
  end

  def same_client?(compare_client)
    client == compare_client
  end

  def same_player?(compare_player)
    player == compare_player
  end

  def name
    player.name
  end
end
