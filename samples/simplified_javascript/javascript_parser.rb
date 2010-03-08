$: << File.dirname(__FILE__) + '/../../lib'
$: << File.dirname(__FILE__)
require 'radish'

module Radish::TokenInstanceMethods
  # TODO: Build a better way to inject such methods into TIM.
  def delimited_list(separator, terminator, options={})
    result = []
    until looking_at?(terminator)
      loop do
        result << yield
        advance_if_looking_at separator or break
        break if options[:allow_extra] && looking_at?(terminator)
      end
    end
    advance_if_looking_at! terminator
    result
  end
end

module RadishSamples
  class SimplifiedJavaScriptParser < Radish::Parser
    
    def module_for_token(token)
      return super(token, token.text.to_sym) if [:operator, :name].include?(token.type)
      super
    end
    protected :module_for_token
  
    def self.infix(type, lbp, options={:assoc => :left}, &infix_blk)
      unless [:left, :right].include?(options[:assoc])
        raise Radish::GrammarError("Invalid :assoc option: #{options[:assoc]}")
      end
      rbp = (options[:associativity] == :left) ? lbp : lbp - 1

      tok_module = deftoken(type, lbp)
      infix_blk = lambda{|left| [type, left, expression(rbp)] } unless block_given?
      tok_module.infix &infix_blk
    end
  
    def self.prefix(type, &prefix_blk)
      tok_module = deftoken(type)
      prefix_blk = lambda{ [type, expression(70)] } unless block_given?
      tok_module.prefix &prefix_blk
    end    
  
    def self.symbol(type, bp=0, &prefix_blk)
      tok_module = deftoken(type, bp)
      tok_module.prefix(&prefix_blk) if block_given?
    end
  
    # --------------------------------------------------- symbols and constants
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
  
    # --------------------------------------------------------- unary operators
    prefix :-
    prefix :'!'
    prefix :typeof
    
    # ---------------------------------------------------- compound expressions
    prefix :'(' do
      returning(expression(0)) { advance_if_looking_at!(:')') }
    end
    
    prefix :'[' do
      [:array] + delimited_list(:',', :']') { expression(0) }
    end
    
    prefix :'{' do
      keyvals = delimited_list(:',', :'}') do
        key = take_token
        raise key, "Bad property name" unless [:string, :number].include?(key.type)
        advance_if_looking_at! :':'
        [key.prefix, expression(0)]
      end
      [:object, *keyvals.flatten(1)]
    end
    
    # TODO: while I was working on the other prefix tokens I plugged this in,
    #       but it depends on scope and statements, and I'd rather tackle those
    #       with smaller things before getting this to work.
    # prefix :function do
    #   new_scope
    #
    #   name = advance_if_looking_at(:name)
    #   scope.define(name) if name
    #
    #   advance_if_looking_at! :'('
    #   args = delimited_list(:',', :')') do
    #     raise next_token, "Expected a parameter name" unless looking_at? :name
    #     param = take_token
    #     scope.define(param)
    #     param
    #   end
    #
    #   advance_if_looking_at! :'{'
    #   body = statements()
    #   advance_if_looking_at! :'}'
    #
    #   scope.pop
    #   [:function name args body]
    # end
    
    # --------------------------------------------------------- infix operators
    infix :'?',   20 do |left|
      middle = expression(0)
      advance_if_looking_at! :':'
      right = expression(0)
      [:'?', left, middle, right]
    end
    
    infix :'&&',  30, :assoc => :right
    infix :'||',  30, :assoc => :right

    infix :'===', 40, :assoc => :right
    infix :'!==', 40, :assoc => :right
    infix :'<',   40, :assoc => :right
    infix :'<=',  40, :assoc => :right
    infix :'>',   40, :assoc => :right
    infix :'>=',  40, :assoc => :right

    infix :'+',   50
    infix :'-',   50
                  
    infix :'*',   60
    infix :'/',   60
          
    # TODO: not tested yet.
    infix :'.',   80 do |left|
      # ??? Don't really have the concept of arity in our impl.  What's the equivalent?
      raise next_token, "Expected a property name." unless next_token.arity == 'name'
      [:propref, left, take_token]
    end

    infix :'[',   80 do |left|
      returning([:lookup, left, expression(0)]) { advance_if_looking_at! :']' }
    end

    infix :'(',   80 do |left|
      # ??? raise if left is not something callable
      [:call, left, delimited_list(:',', :')'){ expression(0) }]
    end
    
    # -------------------------------------------------------------- statements
    
  end
end
