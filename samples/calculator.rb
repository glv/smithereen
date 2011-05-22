require 'rubygems'
require 'active_support/core_ext/object/returning'
require 'smithereen'

module SmithereenSamples
  class CalculatorLexer < Smithereen::Lexer
    def produce_next_token  
      return nil if i >= length

      rest = s[i..-1]
    
      case rest
      when /\A\s+/m
        move $&.size
        produce_next_token
      when /\A\d+/ then make_token(:integer, $&)
      when /\A\+/  then make_token(:+,       $&)
      when /\A-/   then make_token(:-,       $&)
      when /\A\*/  then make_token(:*,       $&)
      when /\A\//  then make_token(:/,       $&)
      when /\A\^/  then make_token(:'^',     $&)
      when /\A\(/  then make_token(:'(',     $&)
      when /\A\)/  then make_token(:')',     $&)
      end
    end
  end
  
  class CalculatorGrammar < Smithereen::Grammar
    
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
    
    deftoken :/, 20 do
      infix {|left| left / expression(lbp) }
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
        returning(expression) { advance_if_looking_at! :')' }
      end
    end
  
    deftoken :')', 0

  end

  class Calculator < Smithereen::Parser
    def initialize(s)
      super(CalculatorGrammar.new, CalculatorLexer.new(s))
    end    
  end
end
