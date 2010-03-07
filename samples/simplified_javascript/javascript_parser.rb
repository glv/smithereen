$: << File.dirname(__FILE__) + '/../../lib'
$: << File.dirname(__FILE__)
require 'radish'

module RadishSamples
  class JavaScriptParser < Radish::Parser
  
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
          infix do |left|
<<<<<<< HEAD
            [type, left, expression(rbp)]
=======
            [:call, left, type, [:array, expression(rbp)]]
>>>>>>> e5f287084a80dad938aa901913a99279d22b59b3
          end
        end
      end
    end
  
    def self.infix(type, bp, &infix_blk)
      infix_base(type, bp, bp, &infix_blk)
    end
  
    def self.infixr(type, bp, &infix_blk)
      infix_base(type, bp, bp-1, &infix_blk)
    end
  
    def self.symbol(type, bp=0, &prefix_blk)
      deftoken(type, bp) do
        prefix(&prefix_blk)
      end
    end
  
    class <<self
      protected :infix_base
    end
  
    symbol :number do
      [:lit, text =~ /\./ ? text.to_f : text.to_i]
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
      self.first = left
      # ??? what's token here?
      raise token, "Expected a property name." unless token.arity == 'name'
      token.arity = 'literal'
      self.second = token
      self.arity = 'binary'
      take_token
      self
    end

    infix  :'[',   80 do |left|
      self.first = left
      self.second = expression(0)
      self.arity = 'binary'
      advance_if_looking_at :']'
      self
    end

    infix  :'(',   80 do |left|
      a = []
      self.first = left
      self.second = a
      self.arity = 'binary'
      if (left.arity != 'unary' || left.tok_id != 'function') \
         && left.arity != 'name' \
         && (left.arity != 'binary' \
             || (left.type != :'.' && left.type != :'(' && left.type != :'[')
            )
        raise left, "Expected a variable name"
      end
      # ??? what's token here?
      if token.type != :')'
        loop do
          a << expression(0)
          break unless token.type == :','
          advance_if_looking_at :','
        end
      end
      advance_if_looking_at :')'
      self
    end

  end
end
