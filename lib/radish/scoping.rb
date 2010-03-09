module Radish
  module Scoping

    class Scope
      attr_reader :defs
      attr_reader :parent
      attr_reader :parser
      
      def initialize(parser, parent)
        @parser = parser
        @parent = parent
        @defs = {}
      end
      
      # What is name? a token or a symbol module?
      # It's a token.  But in here, we augment it into sort of a null symbol.
      # That null symbol is returned.
      def define(name)
        if t = defs[name.text]
          raise name, "Already #{t.reserved ? 'reserved' : 'defined'}" 
        end
        
        store(name, false)
      end
      
      # What is name? a token or a symbol module?
      # Name is just a name this time.
      # But the stored module-ish is returned.
      def find(name)
        current = self
        while current
          if name_module = defs[name]
            return name_module
          end
          current = current.parent
        end
        
        return parser.symbol_table[name] || :name
      end
      
      # What is name? a token or a symbol module?
      # a token this time, and it *doesn't* get turned into a module.
      def reserve(name)
        # TODO: is the guard before calling reserved necessary?
        return if name.type != :name || (name.respond_to?(:reserved) && name.reserved)
        if name_module = defs[name.text]
          return if name_module.reserved
          # TODO: how could anything with type != :name get in there?
          raise name, "Already defined" if name_module.type == :name
        end
        
        store(name, true)
      end

      def pop
        parser.scope = parent;
      end     
      
      protected
      
      def store(name, reserved)
        returning parser.new_token_module(:name, 0) do |name_module|
          defs[name.text] = name_module
          name_module.module_eval do
            mattr_accessor :reserved
            mattr_accessor :scope
          
            prefix {self}
          end
          name_module.reserved = reserved
          name_module.scope = self
        end
      end 
    end
    
    attr_reader :scope
    
    def new_scope
      @scope = Scope.new(self, scope)
    end
    
  end
end
