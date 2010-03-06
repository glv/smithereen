$: << File.dirname(__FILE__) + '/../lib'
$: << File.dirname(__FILE__)

require 'rubygems'
require 'active_support/core_ext/object/returning'
require 'radish'

class ExampleLexer < Radish::Lexer
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

class ExampleParser < Radish::Parser
  def initialize(s)
    super(ExampleLexer.new(s))
  end
  
  deftoken :integer, 1000 do
    def value
      @value ||= text.to_i
    end
    
    prefix { value }
  end
  
  deftoken :+, 10 do
    infix {|left| left + expression(lbp) }
  end
  
  deftoken :*, 20 do
    infix {|left| left * expression(lbp) }
  end
  
  deftoken :-, 10 do
    prefix { - expression(lbp) }
    infix {|left| left - expression(lbp) }
  end
  
  deftoken :'^', 30 do
    infix {|left| left ** expression(lbp - 1) }
  end
  
  deftoken :'(', 0 do
    prefix do
      returning(expression) { advance_if_looking_at :')' }
    end
  end
  
  deftoken :')', 0
end

puts ExampleParser.new("24").parse
puts ExampleParser.new("24+2").parse
puts ExampleParser.new("24+2*3").parse
puts ExampleParser.new("24+2*-3-12").parse
puts ExampleParser.new("24+2*(-3-12)").parse
puts ExampleParser.new("24+2*-(3-12)").parse
puts ExampleParser.new("24+2*-(3-12 ^ 2)").parse
