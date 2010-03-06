module Radish
  class GrammarError < Exception
  end
  
  class ParseError < Exception
    def initialize(msg, token)
      super(msg)
      @token = token
    end
    
    def to_s
      "#{super}: #{@token}"
    end
  end
end
