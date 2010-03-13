require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/parser'

describe Radish::Parser do
  Parser = Radish::Parser
  class MockGrammar < Radish::Grammar; end
  
  describe "instance methods" do
    subject do
      Parser.new(MockGrammar.new, :foo) 
    end
    
    describe "#initialize" do
      
      it "stores the passed grammar" do
        grammar = MockGrammar.new
        Parser.new(grammar, :foo).grammar.should == grammar
      end
      
      it "stores the passed lexer" do
        subject.lexer.should == :foo
      end
      
      it "sets grammar.parser to self" do
        subject.grammar.parser.should == subject
      end
    end
    
    describe "#symbol_table" do
      it "delegates to the grammar" do
        mock(subject.grammar).symbol_table{:some_table}
        subject.symbol_table.should == :some_table
      end
    end
    
    describe "#symbolize" do
      it "delegates to the grammar" do
        mock(subject.grammar).symbolize(:foo){:symbolized_foo}
        subject.symbolize(:foo).should == :symbolized_foo
      end
    end
    
    describe "#parse_expression" do
      it "returns the value returned by expression" do
        mock(subject).expression { :some_result }
        stub(subject).advance_if_looking_at!
        subject.parse.should == :some_result
      end
      
      it "advances past the (end) token after parsing the expression" do
        mock(subject) do |expect|
          expect.expression.ordered { :some_result }
          expect.advance_if_looking_at!(Radish::Grammar::END_TOKEN_TYPE).ordered
        end
        subject.parse
      end
    end
    
    describe "#parse" do
      it "delegates to parse_expression" do
        mock(subject).parse_expression{:some_tree}
        subject.parse.should == :some_tree
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
    
    describe "#concatenated_list" do
    end
    
    describe "#separated_list" do
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
          expect.symbol_table.mock![:some_type].mock!.to_msg{'some_type'}
        end
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
        end_tok = Radish::LexerToken.new(Radish::Grammar::END_TOKEN_TYPE, '')
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
    
  end
  
  describe "(end) token" do    
    it "reports 'Unexpected end of input' when prefix is called" do
      lexer = mock!.take_token{nil}.times(2).subject
      parser = Class.new(Parser).new(MockGrammar.new, lexer)
      lambda{parser.send(:take_token).prefix}.should raise_error(Radish::ParseError, "Unexpected end of input: #{parser.send(:take_token)}")
    end
    
    describe "#to_msg" do
      it "returns 'end of input'" do
        lexer = mock!.take_token{nil}.subject
        parser = Class.new(Parser).new(MockGrammar.new, lexer)
        parser.send(:take_token).to_msg.should == 'end of input'
      end
    end
  end

end

describe Radish::StatementParser do
  StatementParser = Radish::StatementParser
  class MockGrammar < Radish::Grammar; end
  
  subject do
    StatementParser.new(MockGrammar.new, :foo) 
  end
  
  describe "#initialize" do
    it "creates a new scope"
  end
  
  describe "#parse_statement" do
    it "parses a statement"
  end
  
  describe "#parse" do
    it "parses a file consisting of a sequence of statements."
  end
  
  describe "#statement" do
    it "parses a statement"
    it "delegates to expression_statement if not looking at a true statement"
  end
  
  describe "#expression_statement" do
    it "parses an expression as a statement"
  end
  
  describe "#statements" do
    it "parses a series of statements, up to a terminator"
  end
  
end