module Radish
  Token = Struct.new(:type, :tvalue, :from, :to)
  
  class Lexer
    attr_accessor :i
    attr_reader :length, :s
    protected :i, :i=, :length, :move, :s
    
    def initialize(s)
      @s = s
      @i = 0
      @length = @s.size
      @result = []
      init_op_re
    end
    
    def move(incr=1)
      @i += incr
    end

    def next_token
      return @next_token if @next_token
    end
    
    def take_token
      next_token
    else
      @next_token = nil
    end
  end
end