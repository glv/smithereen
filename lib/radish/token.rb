require 'active_support/core_ext/module/delegation'
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
    
    def to_msg
      type.to_s =~ /^\w+$/ ? type.to_s : "'#{type}'"
    end
    
    def to_s
      to_msg
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
    
    # TODO: I keep forgetting to put things here.  Is there a better way?
    delegate :advance_if_looking_at, 
             :advance_if_looking_at!,
             :block,
             :concatenated_list,
             :expression, 
             :looking_at?,
             :new_scope,
             :next_token,
             :statement,
             :statements, 
             :symbol_table,
             :take_token, 
        :to => :parser
    
    def to_msg
      if type.to_s == text
        "'#{text}'"
      else
        "#{type} (#{text})"
      end
    end
    
    def prefix
      raise ::Radish::ParseError.new("Unexpected #{to_msg}", self)
    end

    def infix(left)
      raise ::Radish::ParseError.new("Unexpected #{to_msg}", self)
    end
    
    def exception(message="Parse error")
      ::Radish::ParseError.new(message, self)
    end
  end
end