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
  class SimplifiedJavaScriptParser < Radish::Parser
    include Radish::Scoping
    
    def initialize(source_lexer)
      super
      new_scope
    end
    
    def module_for_token(token)
      # TODO: when scope is ready
      # return scope.find(token.text) if token.type == :name
      # and then remove :name from the special handling on the next line
      return super(token, token.text.to_sym) if [:operator, :name].include?(token.type)
      super
    end
    protected :module_for_token
    
    def parse_statement
      returning(statement) { advance_if_looking_at! END_TOKEN_TYPE }
    end
    
    def parse_expression
      parse
    end
    
    def statement
      if next_token.respond_to?(:stmt)
        # TODO: scope reserve.  Why?
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
      # TODO: reserve in default prefix method
      prefix_blk = lambda{ [type, expression(70)] } unless block_given?
      tok_module.prefix &prefix_blk
    end    
  
    def self.symbol(type, bp=0, &prefix_blk)
      tok_module = deftoken(type, bp)
      tok_module.prefix(&prefix_blk) if block_given?
    end
    
    def self.stmt(type, &stmt_blk)
      deftoken(type) do
        stmt &stmt_blk
      end
    end
  
    # --------------------------------------------------- symbols and constants
    # symbol :name
    symbol :':'
    symbol :';'
    symbol :')'
    symbol :']'
    symbol :'}'
    symbol :','
    # symbol :else
    
    # constant :true,  true
    # constant :false, false
    # constant :null,  nil
    # constant :pi,    3.141592653589793
    
    # symbol :this
    
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
    # assignment :'='
    # assignment :'+='
    # assignment :'-='
    
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
      right = advance_if_looking_at(:name) or 
          raise next_token, "Expected a property name."
      [:propref, left, right]
    end

    infix :'[',   80 do |left|
      returning([:lookup, left, expression(0)]) { advance_if_looking_at! :']' }
    end

    infix :'(',   80 do |left|
      # ??? raise if left is not something callable
      [:call, left, delimited_list(:',', :')'){ expression(0) }]
    end
    
    # -------------------------------------------------------------- statements
    # stmt :'{'
    # stmt :var
    # stmt :if
    
    stmt :return do
      returning [:return] do |result|
        result << expression(0) unless looking_at? :';'
        advance_if_looking_at! :';'
        # TODO: remove '|| looking_at?(END_TOKEN_TYPE) when blocks are supported.
        #       return should only be permitted in a block.
        raise next_token, "Unreachable statement" unless looking_at?(:'}') || looking_at?(END_TOKEN_TYPE)
      end
    end
    
    stmt :break do
      advance_if_looking_at! :';'
      # TODO: remove '|| looking_at?(END_TOKEN_TYPE) when blocks are supported.
      #       break should only be permitted in a block.
      raise next_token, "Unreachable statement" unless looking_at?(:'}') || looking_at?(END_TOKEN_TYPE)
      [:break]
    end
    
    # stmt :while
    
  end
end
