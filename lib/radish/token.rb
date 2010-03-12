require 'active_support/core_ext/module/delegation'
require 'radish/errors'

module Radish
  module TokenClassMethods
    def prefix(&blk)
      defblock :prefix, &blk
    end
    
    def infix(&blk)
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
    
    def method_missing(meth, *args, &blk)
      if parser.respond_to?(meth)
        parser.send(meth, *args, &blk)
      else
        super
      end
    end
    
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