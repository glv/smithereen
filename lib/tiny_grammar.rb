$: << File.dirname(__FILE__)
require 'radish'

$symbol_table = {}

module Radish
  module SymbolInstanceMethods
    attr_accessor :symbol_module, :arity, :parser, :first, :second, :third, :key
    attr_writer :name  # not sure what good this does ... never used.
    
    # TODO: this should be diagnostic
    def tree(lines=[''], indent=0)
      lines.last << '{'
      indent += 4
      #puts self.inspect, self.value
      lines << "#{' '*indent}#{value} (#{arity})"
      %w{first second third}.each do |ord|
        if (p = self.send(ord.to_sym)) 
          lines << "#{' '*indent}#{ord}: "
          # puts p.inspect, p.value
          p.tree(lines, indent)
        end
      end
      indent -= 4
      lines << "#{' '*indent}}"
    end  
    
    def advance(id=nil)
      parser.advance(id)
    end
    
    def token
      parser.token
    end
    
    def scope=(scope)
      @scope = scope
    end
    
    def scope
      @scope || parser.scope
    end
    
    def new_scope
      parser.new_scope
    end
    
    def statements
      parser.statements
    end
    
    def expression(rbp)
      parser.expression(rbp)
    end
    
    def tok_id
      @symbol_module.tok_id
    end

    def lbp
      @symbol_module.lbp
    end

    def lbp=(lbp)
      @symbol_module.lbp = lbp
    end

    def value
      text || @symbol_module.default_value || nil
    end

    #attr_writer :value

    def error(msg)
      raise self, msg
    end

    def nud
      error "unexpected '#{text}'"
    end

    def led(left)
      error 'Missing operator.'
    end
  end

  module SymbolClassMethods
    def tok_id
      @tok_id
    end
    
    def tok_id=(id)
      @tok_id = id
    end

    def default_value=(value)
      @default_value = value
    end
    
    def default_value
      @default_value
    end

    def lbp
      @lbp
    end

    def lbp=(lbp)
      @lbp = lbp
    end

    def nudproc(&proc)
      defproc :nud, &proc
    end

    def ledproc(&proc)
      defproc :led, &proc
    end

    def stdproc(&proc)
      defproc :std, &proc
    end

    protected

    def defproc(sym, &proc)
      if block_given?
        define_method(sym, &proc)
      else
        undef_method sym
      end
    end

  end

  class Parser
    attr_accessor :token
    attr_reader :lexer
    
    def initialize(lexer)
      @lexer = lexer
    end
    
    def take_token
      tok = lexer.take_token
      tok
    end
    
    def next_token
      tok = lexer.next_token
      tok
    end
    
    # TODO: I like this as core; statement-oriented languages
    #       can override, or perhaps subclass StatementParser
    #       or something.
    def parse
      advance
      s = expression
      advance '(end)'
      s
    end
    
    # TODO: don't like this name
    def symbolize_token(tok, sym, t_type)
      unless sym.kind_of? Module
        puts sym.tree
        sym = sym.symbol_module
      end
      
      tok.extend sym
      tok.symbol_module = sym
      tok.parser = self
      tok.arity = t_type
      tok
    end
    
    # TODO: don't like this name
    def advance(tok_id=nil)
      raise token, "Expected '#{tok_id}'" if tok_id && token.tok_id != tok_id

      t = take_token || Radish::LexerToken.new(:'(end)')
      t_text, t_type = t.text, t.type
      
      if t_type == :"(end)"
        self.token = symbolize_token(t, $symbol_table['(end)'], t_type)
        return
      end

      case t_type
      when :+
        o = $symbol_table[t_text]
        raise t, "Unknown operator" unless o
      when :integer
        o = $symbol_table['(literal)']
        t_type = :literal
      else
        raise t, "Unexpected token"
      end

      # ??? Rather than setting token to t, Crockford is creating a new
      # ??? object based on o (which was fetched from the symbol table or
      # ??? scope) and annotating it with value, arity, from, and to.  That
      # ??? object is set as the token.
      # ??? 
      # ??? What that means is that the object needs to get the nud and led
      # ??? methods, id, and lbp from o.
      # ???
      # ??? I'm thinking now that the things in the symbol table need to be
      # ??? modules, and they can be included directly in the token object.
      # ???
      # ??? Like this:
      self.token = symbolize_token(t, o, t_type)
    end

    # TODO: is this core? probably
    def expression(rbp=0)
      t = token
      advance
      left = t.nud
      while rbp < token.lbp
        t = token
        advance
        left = t.led(left)
      end
      left
    end

    class <<self
      def symbol(id, bp=0, &nud)
        if s = $symbol_table[id]
          s.lbp = bp if bp >= s.lbp
        else
          s = make_symbol(id, bp)
          $symbol_table[id] = s
        end
        if block_given?
          s.nudproc &nud
        end
        s
      end

      def make_symbol(id, bp)
        s = Module.new
        s.module_eval do
          include SymbolInstanceMethods
          extend SymbolClassMethods
        end
        s.tok_id = id
        s.default_value = id
        s.lbp = bp
        s
      end

      def infix_base(id, bp, rbp, &led)
        s = symbol(id, bp)
        if block_given?
          s.ledproc &led
        else
          s.ledproc do |left|
            self.first = left
            self.second = expression(rbp)
            self.arity = 'binary'
            self
          end
        end
        s
      end

      protected :infix_base

      def infix(id, bp, &led)
        infix_base(id, bp, bp, &led)
      end
    end
    
  end
  
end

class TinyGrammar < Radish::Parser
  def initialize(source)
    l = ::Radish::Lexer.new(source)
    super(l)
  end
  
  symbol '(end)' do
    error "unexpected end-of-file"
  end
  symbol '(literal)' do 
    self 
  end
  
  infix  '+',   50
end

puts TinyGrammar.new('1 + 2 + 3').parse.tree
#puts TinyGrammar.new('+2').parse.tree
#puts TinyGrammar.new('2+').parse.tree
# puts TinyGrammar.new('1').parse.tree
