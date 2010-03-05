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
    attr_reader :token
    
    def initialize(source_lexer)
      @lexer = source_lexer
    end
    
    def symbol_table
      self.class.symbol_table
    end
    
    def parse
      advance
      # TODO: use returning
      s = expression
      advance_if_looking_at END_TOKEN_TYPE
      s
    end
    
    def expression(rbp=0)
      t = token
      advance
      left = t.nud
      while rbp < token.lbp
        t = token
        advance
        left = t.led(left)
      end
      left
    end
    
    def advance_if_looking_at(type)
      raise token, "Expected '#{type}'" if token.type != type
      advance
    end

    protected
    
    attr_writer :token
    
    def next_token
      # TODO: This means that advance returns augmented tokens for the parser,
      #       but next_token simply returns LexerTokens.  Right now that's all we
      #       need, but it feels wrong.
      lexer.next_token
    end
    
    def advance
      tok = lexer.take_token || LexerToken.new(END_TOKEN_TYPE, '')
      token_module = symbol_table[tok.type]

      raise tok, "Unrecognized token type from lexer" if token_module.nil?

      tok.extend(token_module)
      tok.parser = self
      self.token = tok
    end
    
  end
  
  # TODO: haven't tested or really explored this yet.
  #       Just put it in here from Crockford's JS parser
  #       to remind me to think about statement-oriented languages.
  class StatementParser < Parser
    def parse
      advance
      # TODO: use returning
      s = statements  # TODO: some notion of "what's the top level we're looking for?"
      advance_if_looking_at END_TOKEN_TYPE
      s
    end
    
    # TODO: add std to token modules somehow.
    
    def statement
      n = token
      if n.respond_to? :std
        advance
        return n.std
      end
      v = expression(0)
      # TODO: check for bad expression statements somehow
      # TODO: advance over statement terminator
    end
    
    # TODO: need a similar thing for expressions: a method
    #       that just parses and gathers up a sequence of expressions.
    def statements
      a = []
      loop do
        break if token.type == :'}' || token.type == END_TOKEN_TYPE
        s = statement
        a << s if s
      end
      case a.length
      when 0: nil
      when 1: a[0]
      else    a
      end
    end
  end
end
