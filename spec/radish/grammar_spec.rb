require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/parser'

describe Radish::Grammar do
  Grammar = Radish::Grammar
  
  before do
    Grammar.symbol_table.clear
  end

  describe "instance methods" do
    subject{Grammar.new}
    
    describe "#initialize" do
      it "sets its symbol table to a copy of the class symbol table" do
        mock(Grammar.symbol_table).dup{:symbol_table_copy}
        Grammar.new.symbol_table.should == :symbol_table_copy
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
        subject.parser = :some_parser
        token = mock!.extend(:some_module).subject
        stub(token).parser = :some_parser
        mock(subject).module_for_token(token){:some_module}
        subject.send(:symbolize, token).should == token
      end
      
      it "sets the parser value on the token" do
        subject.parser = :some_parser
        mock(token = 'some token').parser = :some_parser
        stub(token).extend
        stub(subject).module_for_token(token){:some_module}
        subject.send(:symbolize, token).should == token
      end
    end    
  end

  describe "class methods" do
    
    describe "::inherited" do
      it "defines the (end) token in a new subclass's symbol table" do
        c = Class.new(Grammar)
        c.symbol_table[Grammar::END_TOKEN_TYPE].should be_a(Module)
      end
    end

    describe "::symbol_table" do      
      it "is not shared with subclasses" do
        Grammar.symbol_table[:foo] = 'bar'
        c = Class.new(Grammar)
        c.symbol_table[:baz] = 'quux'

        Grammar.symbol_table[:foo].should == 'bar'
        Grammar.symbol_table[:baz].should be_nil

        c.symbol_table[:foo].should be_nil
        c.symbol_table[:baz].should == 'quux'
      end
    end
    
    describe "::new_token_module" do
      it "creates and returns a new module" do
        stub(mock_module = Object.new) do |allow|
          allow.lbp = 0
          allow.type = :foo
        end
        mock(Module).new{mock_module}
        Grammar.new_token_module(:foo, 0).should == mock_module
      end
      
      it "extends that module with TokenClassMethods" do
        Grammar.deftoken(:foo, 0)
        m = Grammar.symbol_table[:foo]
        m.respond_to?(:prefix).should be_true
      end
    
      it "includes TokenInstanceMethods into that module" do
        Grammar.deftoken(:foo, 0)
        m = Grammar.symbol_table[:foo]
        m.included_modules.should =~ [Radish::TokenInstanceMethods]
      end
    
      it "defines #type to return the supplied type value" do
        Grammar.deftoken(:foo, 0)
        o = Object.new
        o.extend Grammar.symbol_table[:foo]
        o.type.should == :foo
      end
    
      it "defines #lbp accessor to return the supplied lbp value" do
        Grammar.deftoken(:foo, 35)
        o = Object.new
        o.extend Grammar.symbol_table[:foo]
        o.lbp.should == 35
      end
    end

    describe "::deftoken" do
      it "creates a new token module and stores it in the symbol table" do
        mock_module = 'bar'
        mock(Grammar).new_token_module(:foo, 0){mock_module}
        Grammar.deftoken(:foo, 0)
        Grammar.symbol_table[:foo].should == mock_module
      end
      
      it "does not create a new module if a module for the type already exists" do
        Grammar.deftoken(:foo, 0)
        dont_allow(Grammar).new_token_module
        Grammar.deftoken(:foo, 0)
      end
    
      it "uses 0 as a default lbp value" do
        Grammar.deftoken(:foo)
        o = Object.new
        o.extend Grammar.symbol_table[:foo]
        o.lbp.should == 0
      end
    
      it "evals a supplied block in the module" do
        block_module = nil
        Grammar.deftoken(:foo, 0) do
          block_module = self
        end
        block_module.should == Grammar.symbol_table[:foo]
      end
      
      it "evals a supplied block in a preexisting module" do
        Grammar.deftoken(:foo, 0)
        defined_module = Grammar.symbol_table[:foo]
        block_module = nil
        Grammar.deftoken(:foo, 0) do
          block_module = self
        end
        block_module.should == defined_module
      end
    
      it "redefines lbp on the module if the new lbp is greater than the old" do
        Grammar.deftoken(:foo, 10)
        Grammar.deftoken(:foo, 20)
        o = Object.new
        o.extend Grammar.symbol_table[:foo]
        o.lbp.should == 20
      end      
    end

  end
  
  describe "grammar definition methods" do
    
    describe "symbol" do
      it "returns a new token module"
      it "uses 0 as the default bp value"
      it "registers the passed block as the module's prefix method'"
    end
    
    describe "constant" do
      it "returns a new symbol module with the passed type"
      describe "the prefix method" do
        it "reserves the constant name in the current scope"
        it "returns [:lit, value]"
      end
    end
    
    describe "infix" do
      it "returns a new token module"
      it "uses :left as the default :assoc option"
      it "raises an error if an invalid :assoc option is passed"
      it "uses the passed lbp as the rbp if :assoc is :left"
      it "uses lbp-1 as the rbp if :assoc is :right"
      it "registers the passed block as the module's infix method"
      describe "default infix method (used if no block is supplied)" do
        it "returns [type, left, expression(rbp)]"
      end
    end
    
    describe "prefix" do
      it "returns a new token module"
      it "registers the passed block as the module's prefix method"
      describe "default prefix method (used if no block is supplied)" do
        it "reserves the token in the current scope"
        it "returns [type, expression(70)]"
      end
    end
    
  end
  
end

describe Radish::StatementGrammar do
  StatementGrammar = Grammar = Radish::StatementGrammar
  
  before do
    StatementGrammar.symbol_table.clear
  end
  
  describe "grammar definition methods" do
    
    describe "stmt" do
      it "returns a new token module"
      it "registers the passed block as the module's stmt method"
    end
    
  end
  
end
