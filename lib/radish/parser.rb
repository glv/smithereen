require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/returning'
require 'radish/token'

module Radish
  class Parser
    
    attr_reader :grammar
    attr_reader :lexer
    
    delegate :symbol_table, 
             :symbolize,
        :to => :grammar
    
    def initialize(grammar, source_lexer)
      @grammar = grammar
      @lexer   = source_lexer

      grammar.parser = self
    end
    
    def parse_expression
      returning(expression) { advance_if_looking_at! Grammar::END_TOKEN_TYPE }
    end
    
    def parse
      parse_expression
    end
    
    # We use the names 'prefix' and 'infix' instead of Pratt's 'nud' and 'led',
    # following the suggestion from Tom Lynn at 
    # http://eli.thegreenplace.net/2010/01/02/top-down-operator-precedence-parsing/#comment-247017
    
    def looking_at?(type)
      next_token.type == type
    end
    
    # Advances over a token of the supplied type and returns it,
    # or returns nil if the next token is of a different type.
    def advance_if_looking_at(type)
      return nil unless looking_at? type
      take_token
    end

    # Advances over a token of the supplied type and returns it,
    # or raises an error if the next token is of a different type. 
    def advance_if_looking_at!(type)
      advance_if_looking_at(type) or 
          # raise next_token, "Expected #{symbol_table[type].to_msg}, found #{next_token.to_msg} instead"
          raise next_token, "Unexpected #{next_token.to_msg}; expected #{symbol_table[type].to_msg}"
    end

    def expression(rbp=0)
      start_expression = take_token.prefix
      extend_with_infixes(rbp, start_expression)
    end
    
    def concatenated_list(terminator)
      result = []
      until looking_at?(terminator)
        result << yield
      end
      advance_if_looking_at! terminator
      result
    end

    def separated_list(separator, terminator, options={})
      result = []
      until looking_at?(terminator)
        loop do
          result << yield
          advance_if_looking_at separator or break
          break if options[:allow_extra] && looking_at?(terminator)
        end
      end
      advance_if_looking_at! terminator
      result
    end
    
    protected
    
    def extend_with_infixes(rbp, sub_expression)
      sub_expression = take_token.infix(sub_expression) while next_token.lbp > rbp
      sub_expression
    end
    
    attr_writer :next_token
    
    def next_token
      @next_token ||= symbolize(lexer.take_token || LexerToken.new(Grammar::END_TOKEN_TYPE, ''))
    end
    
    def take_token
      returning(next_token) { self.next_token = nil }
    end
    
  end
  
end
