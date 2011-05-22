require 'active_support/core_ext/module/delegation'
require 'smithereen/errors'

module Smithereen
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
      parser.respond_to?(meth) ? parser.send(meth, *args, &blk) : super
    end
    
    def to_msg
      if type.to_s == text
        "'#{text}'"
      else
        "#{type} (#{text})"
      end
    end
    
    def prefix
      raise ::Smithereen::ParseError.new("Unexpected #{to_msg}", self)
    end

    def infix(left)
      raise ::Smithereen::ParseError.new("Unexpected #{to_msg}", self)
    end
    
    def exception(message="Parse error")
      ::Smithereen::ParseError.new(message, self)
    end
  end
  
  module StatementTokenClassMethods
    def stmt(&blk)
      raise ::Smithereen::GrammarError, "stmt blocks must not have positive arity" unless blk.arity <= 0
      defblock :stmt, &blk
      # TODO: do I need to add some explicit indicator that this module is a
      #       statement?  For now I'm using respond_to?(:stmt).  But for prefix
      #       and infix, there's a default implementation that detects a syntax
      #       error.  Is there a case where stmt could be called on a token that's
      #       not a statement, such that we would need such a default implementation
      #       of stmt as well?  If so, we need an explicit flag.
    end
  end
end