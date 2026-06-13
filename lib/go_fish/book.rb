# a representation of four cards of the same value
class Book
  attr_reader :value

  SIZE = 4

  class InvalidValue < StandardError; end

  def initialize(value)
    raise InvalidValue unless value.is_a?(Integer)

    @value = value
  end
end
