require 'radish/errors'

module Radish
  LexerToken = Struct.new(:type, :text, :from, :to) do
    def exception(message="Parse error")
      # TODO: Don't like coupling in this direction.
      ::Radish::ParseError.new(message, self)
    end
  end
end
