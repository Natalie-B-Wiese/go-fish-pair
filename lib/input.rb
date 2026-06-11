class Input
  attr_accessor :has_sent, :value

  def initialize
    @has_sent = false
    @value = nil
  end

  def sent?
    !!has_sent
  end

  def send
    self.has_sent = true
  end

  def unsend
    self.has_sent = false
  end
end
