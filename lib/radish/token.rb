require 'radish/errors'

module Radish
  module TokenClassMethods
    def prefix(&blk)
      raise ::Radish::GrammarError, "prefix blocks must not have positive arity" unless blk.arity <= 0
      defblock :prefix, &blk
    end
    
    def infix(&blk)
      if blk.arity > 1 || blk.arity == 0
        raise ::Radish::GrammarError, "infix blocks must have an arity either 1 or negative"
      end
      defblock :infix, &blk
    end

    protected

    def defblock(sym, &blk)
      if block_given?
        define_method(sym, &blk)
      else
        undef_method sym
      end
    end
  end
  
  module TokenInstanceMethods
    attr_accessor :parser
    
    def prefix
      raise ::Radish::ParseError.new("not expecting call to prefix on #{self.class}", self)
    end

    def infix(left)
      raise ::Radish::ParseError.new("not expecting call to infix on #{self.class}", self)
    end
    
    # TODO: use delegate
    def advance_if_looking_at(type)
      parser.advance_if_looking_at(type)
    end
    
    # TODO: use delegate
    def expression(rbp=0)
      parser.expression(rbp)
    end
  end
end