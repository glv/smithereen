$: << File.dirname(__FILE__) + '/../../lib'
$: << File.dirname(__FILE__)
require 'radish'

module RadishSamples
  class JavaScriptParser < Radish::Parser
    
    protected
    
    def module_for_token(token)
      return super(token, token.text.to_sym) if [:operator, :name].include?(token.type)
      super
    end
  
    # Either need to define :first=, :second=, and :arity= in 
    # another module that gets included in the symbol modules,
    # or define them (or include that module) directly in the
    # blocks here.
    def self.infix_base(type, lbp, rbp, &infix_blk)
      if block_given?
        deftoken(type, lbp) do
          infix(&infix_blk)
        end
      else
        deftoken(type, lbp) do
          infix {|left| [type, left, expression(rbp)] }
        end
      end
    end
  
    def self.infix(type, bp, &infix_blk)
      infix_base(type, bp, bp, &infix_blk)
    end
  
    def self.infixr(type, bp, &infix_blk)
      infix_base(type, bp, bp-1, &infix_blk)
    end
    
    def self.prefix(type, &prefix_blk)
      # TODO: should be able to leave lbp blank here.
      if block_given?
        deftoken(type, 0) do
          prefix(&prefix_blk)
        end
      else
        deftoken(type, 0) do
          prefix { [type, expression(70)] }
        end
      end
    end    
  
    def self.symbol(type, bp=0, &prefix_blk)
      if block_given?
        deftoken(type, bp) do
          prefix(&prefix_blk)
        end
      else
        deftoken(type, bp)
      end
    end
  
    class <<self
      protected :infix_base
    end
  
    symbol :':'
    symbol :')'
    symbol :']'
    symbol :'}'
    symbol :','
    
    symbol :number do
      [:lit, text =~ /\./ ? text.to_f : text.to_i]
    end
    
    symbol :string do
      [:lit, "#{text}"]
    end
  
    prefix :-
    prefix :'!'
    prefix :typeof
    
    prefix :'(' do
      returning(expression(0)) { advance_if_looking_at!(:')') }
    end
    
    # prefix :function
    
    prefix :'[' do
      returning(result = [:array]) do
        if next_token.type != :']'
          loop do
            result << expression(0)
            advance_if_looking_at :',' or break
          end
        end
        advance_if_looking_at! :']'
      end
    end
    
    prefix :'{' do
      returning(result = [:object]) do
        if next_token.type != :'}'
          loop do
            key = take_token
            raise key, "Bad property name" unless [:string, :number].include?(key.type)
            advance_if_looking_at! :':'
            result << [:keyval, key.prefix, expression(0)]
            advance_if_looking_at :',' or break
          end
        end
        advance_if_looking_at! :'}'
      end
    end
    
    infixr :'&&',  30
    infixr :'||',  30

    infixr :'===', 40
    infixr :'!==', 40
    infixr :'<',   40
    infixr :'<=',  40
    infixr :'>',   40
    infixr :'>=',  40

    infix  :'+',   50
    infix  :'-',   50

    infix  :'*',   60
    infix  :'/',   60

    infix  :'.',   80 do |left|
      # ??? Don't really have the concept of arity in our impl.  What's the equivalent?
      raise next_token, "Expected a property name." unless next_token.arity == 'name'
      [:propref, left, take_token]
    end

    infix  :'[',   80 do |left|
      returning([:lookup, left, expression(0)]) { advance_if_looking_at! :']' }
    end

    infix  :'(',   80 do |left|
      # ??? raise if left is not something callable
      args = []
      returning([:call, left, args]) do
        if next_token.type != :')'
          loop do
            args << expression(0)
            advance_if_looking_at :',' or break
          end
        end
        advance_if_looking_at! :')'
      end
    end
    
  end
end
