$: << File.dirname(__FILE__) + '/../../lib'
$: << File.dirname(__FILE__)
require 'radish'

class JavaScriptParser < Radish::Parser
  
  # Either need to define :first=, :second=, and :arity= in 
  # another module that gets included in the symbol modules,
  # or define them (or include that module) directly in the
  # blocks here.
  def self.infix_base(type, lbp, rbp, &led_blk)
    if block_given
      deftoken(type, lbp) do
        led(&led_blk)
      end
    else
      deftoken(type, lbp) do
        led do |left|
          self.first = left
          self.second = expression(rbp)
          self.arity = 'binary'
          self
        end
      end
    end
  end
  
  def infix(type, bp, &led_blk)
    infix_base(type, bp, bp, &led_blk)
  end
  
  def infixr(type, bp, &led_blk)
    infix_base(type, bp, bp-1, &led_blk)
  end
  
  def symbol(type, bp=0, &nud_blk)
    deftoken(type, bp) do
      nud(&nud_blk)
    end
  end
  
  class <<self
    protected :infix_base
  end
  
  symbol :integer
  
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
