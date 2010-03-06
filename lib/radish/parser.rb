require 'radish/token'

module Radish
  class Parser
    END_TOKEN_TYPE = :"(end)"
    
    def self.inherited(klass)
      klass.deftoken END_TOKEN_TYPE, 0
    end
    
    # TODO: should use class_inheritable_accessor
    def self.symbol_table
      @symbol_table ||= {}
    end
    
    def self.deftoken(type, lbp, &blk)
      tok_module = Module.new do
        extend TokenClassMethods
        include TokenInstanceMethods
        define_method(:type) do
          type
        end
        define_method(:lbp) do
          lbp
        end
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
    
    def parse
      # TODO: use returning
      s = expression
      advance_if_looking_at END_TOKEN_TYPE
      s
    end
    
    # We use the names 'prefix' and 'infix' instead of Pratt's 'nud' and 'led'
    # (following suggestion from Tom Lynn here: http://eli.thegreenplace.net/2010/01/02/top-down-operator-precedence-parsing/#comment-247017)
    
    def expression(rbp=0)
      start_expression = take_token.prefix
      extend_with_infixes(rbp, start_expression)
    end
    
    def advance_if_looking_at(type)
      raise next_token, "Expected '#{type}'" if next_token.type != type
      take_token
    end

    protected
    
    attr_writer :next_token
    
    def extend_with_infixes(rbp, sub_expression)
      sub_expression = take_token.infix(sub_expression) while next_token.lbp > rbp
      sub_expression
    end
    
    def next_token
      @next_token ||= symbolize(lexer.take_token || LexerToken.new(END_TOKEN_TYPE, ''))
    end
    
    def take_token
      # TODO: use returning
      token = next_token
      self.next_token = nil
      token
    end
    
    def symbolize(token)
      token_module = symbol_table[token.type]

      raise token, "Unrecognized token type from lexer" if token_module.nil?

      token.extend(token_module)
      token.parser = self
      token
    end
    
  end
  
end
