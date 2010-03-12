require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/parser'

describe Radish::Parser do
  Parser = Radish::Parser
  
  before do
    Parser.symbol_table.clear
  end
  
  describe "class methods" do
  
    describe "::inherited" do
      it "defines the (end) token in a new subclass's symbol table" do
        c = Class.new(Parser)
        c.symbol_table[Parser::END_TOKEN_TYPE].should be_a(Module)
      end
    end
  
    describe "::symbol_table" do
      it "is not shared with subclasses" do
        Parser.symbol_table[:foo] = 'bar'
        c = Class.new(Parser)
        c.symbol_table[:baz] = 'quux'
      
        Parser.symbol_table[:foo].should == 'bar'
        Parser.symbol_table[:baz].should be_nil
      
        c.symbol_table[:foo].should be_nil
        c.symbol_table[:baz].should == 'quux'
      end
    end
  
    describe "::deftoken" do
      it "creates a new module and stores it in the symbol table" do
        mock_module = 'bar'
        stub(mock_module).lbp  = 0
        stub(mock_module).type = :foo
        mock(Module).new{mock_module}
        Parser.send(:deftoken, :foo, 0)
        Parser.symbol_table[:foo].should == mock_module
      end
      
      it "does not create a new module if a module for the type already exists" do
        Parser.send(:deftoken, :foo, 0)
        dont_allow(Module).new
        Parser.send(:deftoken, :foo, 0)
      end
    
      it "extends that module with TokenClassMethods" do
        Parser.send(:deftoken, :foo, 0)
        m = Parser.symbol_table[:foo]
        m.respond_to?(:prefix).should be_true
      end
    
      it "includes TokenInstanceMethods into that module" do
        Parser.send(:deftoken, :foo, 0)
        m = Parser.symbol_table[:foo]
        m.included_modules.should =~ [Radish::TokenInstanceMethods]
      end
    
      it "defines #type to return the supplied type value" do
        Parser.send(:deftoken, :foo, 0)
        o = Object.new
        o.extend Parser.symbol_table[:foo]
        o.type.should == :foo
      end
    
      it "defines #lbp accessor to return the supplied lbp value" do
        Parser.send(:deftoken, :foo, 35)
        o = Object.new
        o.extend Parser.symbol_table[:foo]
        o.lbp.should == 35
      end
      
      it "uses 0 as a default lbp value" do
        Parser.send(:deftoken, :foo)
        o = Object.new
        o.extend Parser.symbol_table[:foo]
        o.lbp.should == 0
      end
    
      it "evals a supplied block in the module" do
        block_module = nil
        Parser.send(:deftoken, :foo, 0) do
          block_module = self
        end
        block_module.should == Parser.symbol_table[:foo]
      end
      
      it "does not create a new module if one already exists for the symbol type" do
        Parser.send(:deftoken, :foo, 0)
        dont_allow(Module).new
        Parser.send(:deftoken, :foo, 0)
      end
      
      it "evals a supplied block in a preexisting module" do
        Parser.send(:deftoken, :foo, 0)
        defined_module = Parser.symbol_table[:foo]
        block_module = nil
        Parser.send(:deftoken, :foo, 0) do
          block_module = self
        end
        block_module.should == defined_module
      end

      it "redefines lbp on the module if the new lbp is greater than the old" do
        Parser.send(:deftoken, :foo, 10)
        Parser.send(:deftoken, :foo, 20)
        o = Object.new
        o.extend Parser.symbol_table[:foo]
        o.lbp.should == 20
      end      
    end
  end
  
  describe "instance methods" do
    subject { Parser.new(:foo) }
    
    describe "#initialize" do
      it "stores the passed lexer" do
        subject.lexer.should == :foo
      end
    end
    
    describe "#symbol_table" do
      it "delegates to the class" do
        c = Class.new(Parser)
        mock(Parser).symbol_table.once
        subject.symbol_table
        mock(c).symbol_table.once
        c.new(:foo).symbol_table
      end
    end
    
    describe "#parse" do
      it "returns the value returned by expression" do
        mock(subject).expression { :some_result }
        stub(subject).advance_if_looking_at!
        subject.parse.should == :some_result
      end
      
      it "advances past the (end) token after parsing the expression" do
        mock(subject) do |expect|
          expect.expression.ordered { :some_result }
          expect.advance_if_looking_at!(Parser::END_TOKEN_TYPE).ordered
        end
        subject.parse
      end
    end
    
    describe "#expression" do
      it "parses a prefix expression and tries to extend it with infixes" do
        mock(subject) do |expect|
          expect.take_token.mock!.prefix { :pre_expr }
          expect.extend_with_infixes(20, :pre_expr) { :in_expr }
        end
        subject.expression(20).should == :in_expr
      end

      it "has a default rbp argument of 0" do
        mock(subject) do |expect|
          expect.take_token.mock!.prefix { :pre_expr }
          expect.extend_with_infixes(0, :pre_expr)
        end
        subject.expression
      end
    end
    
    describe "#extend_with_infixes" do
      it "returns the prefix expression if the next token has a lower lbp" do
        mock(subject).next_token.mock!.lbp { 19 }
        dont_allow(subject).take_token
        subject.send(:extend_with_infixes, 20, :pre_expr).should == :pre_expr
      end
      
      it "returns the prefix expression if the next token has the same lbp" do
        mock(subject).next_token.mock!.lbp { 20 }
        dont_allow(subject).take_token
        subject.send(:extend_with_infixes, 20, :pre_expr).should == :pre_expr
      end
      
      it "gathers infix expressions while they have higher lbps" do
        tok1 = mock! do |expect|
          expect.lbp{30}
          expect.infix(:pre_expr){:in_expr}
        end

        tok2 = mock!.lbp{10}.subject
        dont_allow(tok2).infix

        mock(subject) do |expect|
          expect.next_token{tok1}.ordered
          expect.take_token{tok1}.ordered
          expect.next_token{tok2}.ordered
        end

        subject.send(:extend_with_infixes, 20, :pre_expr).should == :in_expr
      end
    end
    
    describe "#looking_at?" do
      it "returns true if the next token has the requested type" do
        mock(subject).next_token.mock!.type{:some_type}
        subject.looking_at?(:some_type).should be_true
      end
      
      it "returns false if the next token does not have the requested type" do
        mock(subject).next_token.mock!.type{:other_type}
        subject.looking_at?(:some_type).should be_false
      end
    end
    
    describe "#advance_if_looking_at" do
      it "takes and returns the next token if it has the expected type" do
        tok = mock!.type{:some_type}.subject
        mock(subject) do |expect|
          expect.next_token{tok}
          expect.take_token{tok}
        end
        subject.advance_if_looking_at(:some_type).should == tok
      end
      
      it "returns nil if the next token does not have the expected type" do
        # other_token = Radish::LexerToken.new(:other_type, 'ot')
        # lexer = mock!.take_token{other_token}.subject
        # parser = Class.new(Parser).new(lexer)
        # [:some_type, :other_type].each{|t| parser.class.deftoken(t) }
        token = mock!.type{:other_type}.subject
        mock(subject).next_token{token}
        subject.advance_if_looking_at(:some_type).should be_nil
      end
    end
    
    describe "#advance_if_looking_at!" do
      it "returns the result of advance_if_looking_at" do
        mock(subject).advance_if_looking_at(:some_type){:some_token}
        subject.advance_if_looking_at!(:some_type).should == :some_token
      end
         
      it "raises an error if the next token does not have the expected type" do
        other_token = Radish::LexerToken.new(:other_type, 'ot').extend Radish::TokenInstanceMethods
        mock(subject) do |expect|
          expect.advance_if_looking_at(:some_type){nil}
          expect.next_token{other_token}.times(any_times)
        end
        subject.class.deftoken(:some_type)
        lambda{subject.advance_if_looking_at!(:some_type)}.should raise_error(Radish::ParseError, "Unexpected other_type (ot); expected some_type: #{other_token}")
      end
    end
    
    describe "#next_token" do
      it "simply returns the value of @next_token if it's not nil" do
        subject.send(:next_token=, :some_token)
        dont_allow(subject).symbolize
        subject.send(:next_token).should == :some_token
      end
      
      it "returns the next token (symbolized) if @next_token is nil" do
        mock(subject) do |expect|
          expect.lexer.mock!.take_token{:some_token}
          expect.symbolize(:some_token){:symbolized_token}
        end
        
        subject.send(:next_token).should == :symbolized_token
      end
      
      it "returns the (end) token (symbolized) if @next_token is nil and the lexer is empty" do
        end_tok = Radish::LexerToken.new(Parser::END_TOKEN_TYPE, '')
        mock(subject) do |expect|
          expect.lexer.mock!.take_token{nil}
          expect.symbolize(end_tok){:symbolized_token}
        end
        
        subject.send(:next_token).should == :symbolized_token
      end
      
      it "stores the return value in @next_token" do
        mock(subject) do |expect|
          expect.lexer.mock!.take_token{:some_token}
          expect.symbolize(:some_token){:symbolized_token}
        end
        
        subject.send(:next_token)
        subject.instance_variable_get("@next_token").should == :symbolized_token
      end
    end
    
    describe "#take_token" do
      it "returns next_token and sets @next_token to nil" do
        subject.send(:next_token=, :some_token)
        subject.send(:take_token).should == :some_token
        subject.instance_variable_get("@next_token").should be_nil
      end
    end
    
    describe "#new_token_module" do
      it "delegates to the class method" do
        mock(subject.class).new_token_module(:some_type, :some_lbp){:some_module}
        subject.new_token_module(:some_type, :some_lbp).should == :some_module
      end
    end
    
    describe "#module_for_token" do
      it "returns the module from the symbol table for type" do
        subject.symbol_table[:some_type] = :some_module
        subject.send(:module_for_token, :some_token, :some_type).should == :some_module
      end
      
      it "uses token.type as the default value for type" do
        subject.symbol_table[:some_type] = :some_module
        token = mock!.type{:some_type}.subject
        subject.send(:module_for_token, token).should == :some_module
      end
      
      it "raises an error if no module is found" do
        token = Radish::LexerToken.new(:other_type, '').extend Radish::TokenInstanceMethods
        lambda{subject.send(:module_for_token, token)}.should raise_error(Radish::ParseError)
      end
    end
    
    describe "#symbolize" do
      it "extends the token with module_for_token(token)" do
        token = mock!.extend(:some_module).subject
        stub(token).parser = subject
        mock(subject).module_for_token(token){:some_module}
        subject.send(:symbolize, token).should == token
      end
      
      it "sets the parser value on the token" do
        mock(token = 'some token').parser = subject
        stub(token).extend
        stub(subject).module_for_token(token){:some_module}
        subject.send(:symbolize, token).should == token
      end
    end
    
  end
  
  describe "(end) token" do    
    it "reports 'Unexpected end of input' when prefix is called" do
      lexer = mock!.take_token{nil}.times(2).subject
      parser = Class.new(Parser).new(lexer)
      lambda{parser.send(:take_token).prefix}.should raise_error(Radish::ParseError, "Unexpected end of input: #{parser.send(:take_token)}")
    end
    
    describe "#to_msg" do
      it "returns 'end of input'" do
        lexer = mock!.take_token{nil}.subject
        parser = Class.new(Parser).new(lexer)
        parser.send(:take_token).to_msg.should == 'end of input'
      end
    end
  end
end
