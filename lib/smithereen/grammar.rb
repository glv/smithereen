require 'active_support/core_ext/module/attribute_accessors'

module Smithereen
  class Grammar
    END_TOKEN_TYPE = :"(end)"
    
    attr_accessor :parser
    attr_reader :symbol_table

    def initialize
      @symbol_table = self.class.symbol_table.dup
    end
    
    def symbolize(token)
      token.tap do
        token.extend(module_for_token(token))
        token.parser = parser
      end
    end
    
    def module_for_token(token, type=token.type)
      symbol_table.fetch(type) do
        raise ParseError.new("Unrecognized token type from lexer", token)
      end
    end
    
    # ----------------------------------------------------------- Class methods
    def self.inherited(klass)
      klass.deftoken(END_TOKEN_TYPE, 0) do
        def to_msg; 'end of input'; end
        prefix { raise self, "Unexpected end of input" }
      end
    end
    
    def self.symbol_table
      @symbol_table ||= {}
    end
    
    def self.new_token_module(type, lbp)
      tok_module = Module.new do
        extend Smithereen::TokenClassMethods
        include Smithereen::TokenInstanceMethods
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
    
    def self.symbol(type, bp=0, &prefix_blk)
      deftoken(type, bp).tap do |tok_module|
        tok_module.prefix(&prefix_blk) if block_given?
      end
    end

    def self.constant(type, value)
      symbol(type) do
        scope.reserve self
        # TODO: Crockford stores the value in the module, presumably for diagnostic purposes.
        #       We're just maintaining it through closure semantics in this prefix proc.
        # TODO: here we go again with the tree building in what's supposed to be reusable code
        [:lit, value]
      end
    end

    def self.infix(type, lbp, options={:assoc => :left}, &infix_blk)
      unless [:left, :right].include?(options[:assoc])
        raise Smithereen::GrammarError, "Invalid :assoc option: #{options[:assoc]}"
      end
      # TODO: This was broken, yet all the scenarios passed.  Clearly it's not
      #       being tested.
      rbp = (options[:assoc] == :left) ? lbp : lbp - 1

      infix_blk = lambda{|left| [type, left, expression(rbp)] } unless block_given?
      deftoken(type, lbp).tap do |tok_module|
        tok_module.infix &infix_blk
      end
    end
    
    def self.prefix(type, &prefix_blk)
      unless block_given?
        prefix_blk = lambda do
          scope.reserve(self)
          # TODO: why 70?
          [type, expression(70)]
        end
      end
      deftoken(type).tap do |tok_module|
        tok_module.prefix &prefix_blk
      end
    end
    
  end
  
  class StatementGrammar < Grammar
    def self.new_token_module(type, lbp)
      super.tap{|mod| mod.extend Smithereen::StatementTokenClassMethods}
    end

    def self.stmt(type, &stmt_blk)
      deftoken(type) do
        stmt &stmt_blk
      end
    end
  end

end
