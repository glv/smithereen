require 'radish/lexer_token'

module Radish
  class Lexer
    attr_accessor :i
    attr_reader :length, :s
    protected :i, :i=, :length, :s
    
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
    
    def make_token(type, text)
      LexerToken.new(type, text, i, move(text.size))
    end
    
    def produce_next_token  
      return nil if i >= length

      rest = s[i..-1]
      
      case rest
      when /\A\s+/m
        move $&.size
        produce_next_token
      when /\A\d+/
        make_token(:integer, $&)
      when /\A\+/
        make_token(:+, $&)
      when /\A-/
        make_token(:-, $&)
      when /\A\*/
        make_token(:*, $&)
      when /\A\^/
        make_token(:'^', $&)
      when /\A\(/
        make_token(:'(', $&)
      when /\A\)/
        make_token(:')', $&)
      end
    end

  end
end