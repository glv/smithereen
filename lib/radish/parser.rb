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
    
    # Uses prefix and infix instead of Pratt's nud and led
    # (following suggestion from Tom Lynn here: http://eli.thegreenplace.net/2010/01/02/top-down-operator-precedence-parsing/#comment-247017)
    def expression(rbp=0)
      t = take_token
      left = t.prefix
      while rbp < next_token.lbp
        t = take_token
        left = t.infix(left)
      end
      left
    end
    
    def advance_if_looking_at(type)
      raise next_token, "Expected '#{type}'" if next_token.type != type
      take_token
    end

    protected
    
    attr_writer :next_token
    
    def next_token
      # TODO: This means that take_token returns augmented tokens for the parser,
      #       but next_token simply returns LexerTokens.  Right now that's all we
      #       need, but it feels wrong.
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
  
  # TODO: haven't tested or really explored this yet.
  #       Just put it in here from Crockford's JS parser
  #       to remind me to think about statement-oriented languages.
  class StatementParser < Parser
    def parse
      # TODO: use returning
      s = statements  # TODO: some notion of "what's the top level we're looking for?"
      advance_if_looking_at END_TOKEN_TYPE
      s
    end
    
    # TODO: add std to token modules somehow.
    
    def statement
      n = next_token
      if n.respond_to? :std
        take_token
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
