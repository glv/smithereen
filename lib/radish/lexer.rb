require 'radish/lexer_token'

module Radish
  class Lexer

    protected

    attr_accessor :i
    attr_reader :length, :s

    public
    
    def initialize(s)
      @s = s
      @i = 0
      @length = @s.size
    end
    
    def take_token
      produce_next_token
    end

    protected
    
    def move(incr=1)
      @i += incr
    end
    
    def make_token(type, text, size=text.size)
      LexerToken.new(type, text, i, move(size))
    end

  end
end
