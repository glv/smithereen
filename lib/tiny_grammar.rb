$: << File.dirname(__FILE__)
require 'radish'

class ExampleParser < Radish::Parser
  deftoken :integer, 1000 do
    def value
      @value ||= text.to_i
    end
    
    nud { value }
  end
  
  deftoken :+, 10 do
    led {|left| left + expression(lbp) }
  end
  
  deftoken :*, 20 do
    led {|left| left * expression(lbp) }
  end
  
  deftoken :-, 10 do
    nud { - expression(lbp) }
    led {|left| left - expression(lbp) }
  end
  
  deftoken :'^', 30 do
    led {|left| left ** expression(lbp - 1) }
  end
  
  deftoken :'(', 0 do
    nud do
      # TODO: use returning
      expr = expression
      advance_if_looking_at(:')')
      expr
    end
  end
  
  deftoken :')', 0
end

puts ExampleParser.new(Radish::Lexer.new("24")).parse
puts ExampleParser.new(Radish::Lexer.new("24+2")).parse
puts ExampleParser.new(Radish::Lexer.new("24+2*3")).parse
puts ExampleParser.new(Radish::Lexer.new("24+2*-3-12")).parse
puts ExampleParser.new(Radish::Lexer.new("24+2*(-3-12)")).parse
puts ExampleParser.new(Radish::Lexer.new("24+2*-(3-12)")).parse
puts ExampleParser.new(Radish::Lexer.new("24+2*-(3-12 ^ 2)")).parse
