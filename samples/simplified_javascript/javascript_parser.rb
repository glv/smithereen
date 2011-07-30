require 'smithereen'
require 'active_support/core_ext/module/delegation'

module Smithereen::TokenInstanceMethods
  # TODO: Build a better way to inject such methods into TIM.
  delegate :scope, :to => :parser
end

module Smithereen::TokenClassMethods
  # TODO: Build a better way to inject such methods into TCM.
end

module SmithereenSamples
  class SimplifiedJavaScriptGrammar < Smithereen::StatementGrammar
    
    ASSIGNABLE_TYPES = [
      :name,      # a()
      :propref,   # a.b()
      :lookup,    # a[1]()
    ]
        
    def self.assignment(type)
      infix(type, 10, :assoc => :right) do |left|
        # TODO: raise a ParseError here, rather than a StandardError
        raise "Bad lvalue" unless ASSIGNABLE_TYPES.include?(left.first)
        [:assignment, type, left, expression(lbp-1)]
      end
    end

    def module_for_token(token)
      case token.type
      when :name     then return parser.scope.find(token.text)
      when :operator then return super(token, token.text.to_sym)
      else                super
      end
    end
    
    # --------------------------------------------------- symbols and constants
    symbol :name do # TODO: fake symbol; don't like this.
      [:name, text]
    end

    # these are all subordinate to other tokens,
    # so do not need prefix procs.
    symbol :':'
    symbol :';'
    symbol :')'
    symbol :']'
    symbol :'}'
    symbol :','
    symbol :else

    symbol :this do
      scope.reserve(self)
      [:name, 'this']
    end

    constant :true,  true
    constant :false, false
    constant :null,  nil
    constant :pi,    3.141592653589793

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
      expression(0).tap{ advance_if_looking_at!(:')') }
    end

    prefix :'[' do
      [:array] + delimited_sequence(:',', :']') { expression(0) }
    end

    prefix :'{' do
      keyvals = delimited_sequence(:',', :'}') do
        key = take_token
        raise key, "Bad property name" unless [:string, :number, :name].include?(key.type)
        advance_if_looking_at! :':'
        [key.prefix, expression(0)]
      end
      # Could use flatten(1) in 1.8.7 and above
      [:object] + keyvals.inject([]){|accum, keyval| accum += keyval}
    end

    prefix :function do
      name_token = advance_if_looking_at(:name)
      if name_token
        scope.define(name_token)
        name = name_token.prefix
      end

      # Crockford's code had this at the beginning of the method.
      # I think that's a bug.
      new_scope

      advance_if_looking_at! :'('
      args = delimited_sequence(:',', :')') do
        raise next_token, "Expected a parameter name" unless looking_at? :name
        param = take_token
        scope.define(param)
        param.prefix
      end

      advance_if_looking_at! :'{'
      body = statements(:'}')

      scope.pop
      [:function, name, args, body]
    end

    # --------------------------------------------------------- infix operators
    assignment :'='
    assignment :'+='
    assignment :'-='

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

    infix :'.',   80 do |left|
      right = advance_if_looking_at(:name) or
          raise next_token, "Expected a property name."
      [:propref, left, right.prefix]
    end

    infix :'[',   80 do |left|
      [:lookup, left, expression(0)].tap{ advance_if_looking_at! :']' }
    end

    CALLABLE_TYPES = [
      :name,      # a()
      :propref,   # a.b()
      :lookup,    # a[1]()
      :call,      # a()()
      :function,  # (function(){})()
      # TODO: how to distinguish between (function(){})() and function(){}()?
    ]

    infix :'(',   80 do |left|
      # TODO: raise a ParseError here, rather than a StandardError
      raise "Expected a function" unless CALLABLE_TYPES.include?(left.first)
      [:call, left, delimited_sequence(:',', :')'){ expression(0) }]
    end

    # -------------------------------------------------------------- statements
    stmt :'{' do
      new_scope
      [:block, *statements(:'}')].tap do
        scope.pop
      end
    end

    stmt :var do
      decls = delimited_sequence(:',', :';') do
        raise next_token, "Expected a new variable name" unless looking_at?(:name)
        varname = take_token
        scope.define varname
        if advance_if_looking_at :'='
          [varname.prefix, expression(0)]
        else
          [varname.prefix]
        end
      end

      # TODO: raise a ParseError rather than a StandardError
      raise "Expected a variable name in var declaration" if decls.empty?
      [:var, *decls]
    end

    stmt :if do
      advance_if_looking_at! :'('
      test = expression(0)
      advance_if_looking_at! :')'
      if_branch = block
      if looking_at? :else
        scope.reserve next_token
        advance_if_looking_at! :else
        else_branch = looking_at?(:if) ? statement : block
        [:if, test, if_branch, else_branch]
      else
        [:if, test, if_branch]
      end
    end

    stmt :return do
      [:return].tap do |result|
        result << expression(0) unless looking_at? :';'
        advance_if_looking_at! :';'
        raise next_token, "Unreachable statement" unless looking_at?(:'}')
      end
    end

    stmt :break do
      advance_if_looking_at! :';'
      raise next_token, "Unreachable statement" unless looking_at?(:'}')
      [:break]
    end

    stmt :while do
      advance_if_looking_at! :'('
      test = expression(0)
      advance_if_looking_at! :')'
      [:while, test, block]
    end

  end
  
  class SimplifiedJavaScriptParser < Smithereen::StatementParser

    def expression_statement
      super(:';')
    end

    def block
      advance_if_looking_at!(:'{').stmt
    end

  end
      
end
