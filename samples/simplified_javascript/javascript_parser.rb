require 'radish'
require 'active_support/core_ext/module/delegation'

module Radish::TokenInstanceMethods
  # TODO: Build a better way to inject such methods into TIM.
  delegate :scope, :to => :parser
end

module Radish::TokenClassMethods
  # TODO: Build a better way to inject such methods into TCM.
  def stmt(&blk)
    raise ::Radish::GrammarError, "stmt blocks must not have positive arity" unless blk.arity <= 0
    defblock :stmt, &blk
    # TODO: do I need to add some explicit indicator that this module is a
    #       statement?  For now I'm using respond_to?(:stmt).  But for prefix
    #       and infix, there's a default implementation that detects a syntax
    #       error.  Is there a case where stmt could be called on a token that's
    #       not a statement, such that we would need such a default implementation
    #       of stmt as well?  If so, we need an explicit flag.
  end
end

module RadishSamples
  class SimplifiedJavaScriptGrammar < Radish::Grammar
    
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

    def self.stmt(type, &stmt_blk)
      deftoken(type) do
        stmt &stmt_blk
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
      returning(expression(0)) { advance_if_looking_at!(:')') }
    end

    prefix :'[' do
      [:array] + separated_list(:',', :']') { expression(0) }
    end

    prefix :'{' do
      keyvals = separated_list(:',', :'}') do
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
      args = separated_list(:',', :')') do
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
      returning([:lookup, left, expression(0)]) { advance_if_looking_at! :']' }
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
      [:call, left, separated_list(:',', :')'){ expression(0) }]
    end

    # -------------------------------------------------------------- statements
    stmt :'{' do
      new_scope
      returning([:block, *statements(:'}')]) do
        scope.pop
      end
    end

    stmt :var do
      decls = separated_list(:',', :';') do
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
      returning [:return] do |result|
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
  
  class SimplifiedJavaScriptParser < Radish::Parser
    include Radish::Scoping

    def initialize(grammar, source_lexer)
      super
      new_scope
    end

    def parse_statement
      returning(statement) { advance_if_looking_at! Radish::Grammar::END_TOKEN_TYPE }
    end

    def parse
      statements(Grammar::END_TOKEN_TYPE)
    end

    def statement
      if next_token.respond_to?(:stmt)
        # Why reserve here?  Because Crockford is illustrating a flexible
        # reserved word strategy, wherein a word can be used as a variable
        # within a scope if it's not also used as a control word in that
        # same scope.  See http://javascript.crockford.com/tdop/tdop.html#scope
        scope.reserve(next_token)
        return take_token.stmt
      end

      returning expression(0) do |expr|
        # TODO: apparently only assignments and (for some reason) expressions
        #       starting with '(' are allowed as statements.  But for now that
        #       will mess up our testing.
        # raise error unless expr is an assignment or starts with '('
        advance_if_looking_at! :';'
      end
    end

    def statements(terminator)
      concatenated_list(terminator) do
        statement
      end
    end

    def block
      advance_if_looking_at!(:'{').stmt
    end

  end
      
end
