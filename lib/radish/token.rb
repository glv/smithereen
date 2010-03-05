module Radish
  module TokenClassMethods
    def nud(&blk)
      defblock :nud, &blk
    end
    
    def led(&blk)
      defblock :led, &blk
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
    
    def nud
      raise "not expecting call to nud on #{self.class}"
    end

    def led(left)
      raise "not expecting call to led on #{self.class}"
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