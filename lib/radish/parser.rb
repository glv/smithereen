require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object/returning'
require 'radish/token'

module Radish
  class Parser
    END_TOKEN_TYPE = :"(end)"
    
    def self.inherited(klass)
      klass.deftoken(END_TOKEN_TYPE, 0) do
        def to_msg; 'end of input'; end
        prefix { raise self, "Unexpected end of input" }
      end
    end
    
    # TODO: should use class_inheritable_accessor
    def self.symbol_table
      @symbol_table ||= {}
    end
    
    def self.new_token_module(type, lbp)
      tok_module = Module.new do
        extend TokenClassMethods
        include TokenInstanceMethods
        mattr_accessor :lbp
        mattr_accessor :type
      end
      
      tok_module.lbp = lbp
      tok_module.type = type
      tok_module
    end
    
    def self.deftoken(type, lbp=0, &blk)
      tok_module = symbol_table[type]
      if tok_module
        tok_module.lbp = lbp if lbp > tok_module.lbp
      else
        tok_module = new_token_module(type, lbp)
      end
      tok_module.module_eval(&blk) if block_given?
      symbol_table[type] = tok_module
    end
    
    attr_reader :lexer
    
    def initialize(source_lexer)
      @lexer = source_lexer
    end
    
    def symbol_table
      self.class.symbol_table
    end
    
    def parse_expression
      returning(expression) { advance_if_looking_at! END_TOKEN_TYPE }
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
    
    protected
    
    def extend_with_infixes(rbp, sub_expression)
      sub_expression = take_token.infix(sub_expression) while next_token.lbp > rbp
      sub_expression
    end
    
    attr_writer :next_token
    
    def next_token
      @next_token ||= symbolize(lexer.take_token || LexerToken.new(END_TOKEN_TYPE, ''))
    end
    
    def take_token
      returning(next_token) { self.next_token = nil }
    end
    
    def module_for_token(token, type=token.type)
      symbol_table.fetch(type) do
        raise ParseError.new("Unrecognized token type from lexer", token)
      end
    end
    
    def symbolize(token)
      returning token do
        token.extend(module_for_token(token))
        token.parser = self
      end
    end
    
  end
  
end
