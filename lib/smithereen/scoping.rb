require 'active_support/core_ext/module/delegation'

module Smithereen
  module Scoping

    class Scope
      attr_reader :defs
      attr_reader :parent
      attr_reader :parser
      
      delegate :symbol_table, :to => :parser
      
      def initialize(parser, parent)
        @parser = parser
        @parent = parent
        @defs = {}
      end
      
      # Defines 'name' in the scope (if it's not already defined)
      # and returns a binding token module for the token.
      def define(name)
        if t = defs[name.text.to_sym]
          raise name, "Already #{t.reserved ? 'reserved' : 'defined'}" 
        end
        
        # TODO: the goal here is to create a "binding token" module,
        #       (Crockford calls it a "variable token") *and* to augment
        #       the existing token with the variable token stuff.  We're
        #       doing the former in store, but not the latter.
        store(name, false)
      end
      
      # Looks up 'name' and returns the module that reflects its
      # meaning in this scope.
      def find(name)
        current = self
        key = name.to_sym
        while current
          if current.defs.include?(key)
            return current.defs[key]
          end
          current = current.parent
        end
        
        # TODO: use of :name here couples us to Parser too much?
        return symbol_table.fetch(key){symbol_table[:name]}
      end
      
      # Marks 'name' as a reserved word in the scope (if it hasn't
      # already been defined or reserved) and returns a binding
      # module for the token.
      def reserve(name)
        return if name.type != :name || (name.respond_to?(:reserved) && name.reserved)
        if name_module = defs[name.text.to_sym]
          return if name_module.reserved
          raise name, "Already defined"
        end
        
        # TODO: I'm not at all sure that we need to do the binding token module
        #       stuff in this one.
        store(name, true)
      end

      # Discards this scope and makes the parent the current scope again.
      def pop
        parser.scope = parent;
      end     
      
      protected
      
      def store(name, reserved)
        defs[name.text.to_sym] = new_binding_module(reserved)
      end
      
      def new_binding_module(reserved)
        symbol_table[:name].dup.tap do |name_module|
          name_module.module_eval do
            mattr_accessor :reserved
            mattr_accessor :scope
          end
          name_module.reserved = reserved
          name_module.scope = self
        end
      end 
      
    end
    
    attr_accessor :scope
    
    def new_scope
      @scope = Scope.new(self, scope)
    end
    
  end
end
