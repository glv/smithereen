require 'active_support/core_ext/module/delegation'

module Radish
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
      
      # What is name? a token or a symbol module?
      # It's a token.  But in here, we augment it into sort of a null symbol.
      # That null symbol is returned.
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
      
      # What is name? a token or a symbol module?
      # Name is just a name this time.
      # But the stored module-ish is returned.
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
      
      # What is name? a token or a symbol module?
      # a token this time, and it *doesn't* get turned into a module.
      def reserve(name)
        # TODO: is the guard before calling reserved necessary?
        return if name.type != :name || (name.respond_to?(:reserved) && name.reserved)
        if name_module = defs[name.text.to_sym]
          return if name_module.reserved
          raise name, "Already defined"
        end
        
        # TODO: I'm not at all sure that we need to do the binding token module
        #       stuff in this one.
        store(name, true)
      end

      def pop
        parser.scope = parent;
      end     
      
      protected
      
      def store(name, reserved)
        defs[name.text.to_sym] = new_binding_module(reserved)
      end
      
      def new_binding_module(reserved)
        # TODO: would it be possible to dup symbol_table[:name] and add
        #       reserved and scope, so we could just inherit the prefix
        #       method from there?
        returning parser.new_token_module(:name, 0) do |name_module|
          name_module.module_eval do
            mattr_accessor :reserved
            mattr_accessor :scope
          
            # TODO: nasty coupling here. We shouldn't know about tree building.
            prefix {[:name, self.text]}
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
