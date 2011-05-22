require File.dirname(__FILE__) + '/../spec_helper'

require 'smithereen/scoping'
require 'smithereen/errors'

describe Smithereen::Scoping do
  subject { Object.new.extend Smithereen::Scoping }
  
  describe "#new_scope" do
    it "sets a new scope and sets its parent to the old scope" do
      subject.instance_variable_set("@scope", :original_scope)
      subject.new_scope
      subject.scope.should_not == :original_scope
    end
  end
end

describe Smithereen::Scoping::Scope do
  Scope = Smithereen::Scoping::Scope
  
  describe "#initialize" do
    it "stores the supplied parser as #parser" do
      Scope.new(:some_parser, nil).parser.should == :some_parser
    end
    
    it "stores the supplied parent as #parent" do
      Scope.new(nil, :some_parent).parent.should == :some_parent
    end
    
    it "installs an empty hash as #defs" do
      Scope.new(nil, nil).defs.should == {}
    end
  end
  
  describe "#define" do
    subject { Scope.new(nil, nil) }
    
    it "calls 'store' if the name has not been added to this scope" do
      tok = mock!.text{'foo'}.subject
      mock(subject).store(tok, false){:some_module}
      subject.define(tok).should == :some_module
    end
    
    it "raises 'Already defined' if the name is found but not reserved" do
      tok = Smithereen::LexerToken.new(:some_type, 'foo').extend Smithereen::TokenInstanceMethods
      mock(tok).reserved{false}
      subject.defs[:foo] = tok
      lambda{subject.define tok}.should raise_error(Smithereen::ParseError, "Already defined: #{tok}")
    end
    
    it "raises 'Already reserved' if the name has been reserved" do
      tok = Smithereen::LexerToken.new(:some_type, 'foo').extend Smithereen::TokenInstanceMethods
      mock(tok).reserved{true}
      subject.defs[:foo] = tok
      lambda{subject.define tok}.should raise_error(Smithereen::ParseError, "Already reserved: #{tok}")
    end
  end
  
  describe "#find" do
    MockParse = Struct.new(:symbol_table)
    
    subject do
      parser = MockParse.new({})
      parent = Scope.new(parser, nil)
      Scope.new(parser, parent) 
    end

    it "returns the module directly if it has been defined" do
      subject.defs[:foo] = :some_local_module
      subject.find('foo').should == :some_local_module
    end
    
    it "returns the module from the parent scope if it has not been defined locally" do
      subject.parent.defs[:foo] = :some_parent_module
      mock.proxy(subject.defs).include?(:foo)
      mock.proxy(subject.parent.defs)[:foo]
      subject.find('foo').should == :some_parent_module
    end
    
    it "returns the module from the symbol table if it's there but not in a scope" do
      subject.parser.symbol_table[:foo] = :some_symbol_module
      mock.proxy(subject.defs).include?(:foo)
      mock.proxy(subject.parent.defs).include?(:foo)
      mock.proxy(subject.parser.symbol_table).fetch(:foo)
      subject.find('foo').should == :some_symbol_module
    end
    
    it "returns the :name module from the symbol table if nothing else is found" do
      subject.parser.symbol_table[:name] = :some_name_module
      mock.proxy(subject.defs).include?(:foo)
      mock.proxy(subject.parent.defs).include?(:foo)
      mock.proxy(subject.parser.symbol_table).fetch(:foo)
      mock.proxy(subject.parser.symbol_table)[:name]
      subject.find('foo').should == :some_name_module
    end
  end
  
  describe "#reserve" do
    subject { Scope.new(nil, nil) }
    
    it "returns immediately if the token's type is not :name" do
      tok = Smithereen::LexerToken.new(:string, 'foo')
      dont_allow(tok).reserved
      dont_allow(subject) do |prevent|
        prevent.defs
        prevent.store
      end
      subject.reserve(tok).should be_nil
    end
    
    it "returns immediately if the name.reserved" do
      tok = Smithereen::LexerToken.new(:name, 'foo')
      mock(tok).reserved{true}
      dont_allow(subject) do |prevent|
        prevent.defs
        prevent.store
      end
      subject.reserve(tok).should be_nil
    end
    
    it "returns immediately if the name has been reserved locally" do
      tok = Smithereen::LexerToken.new(:name, 'foo')
      mock(tok).reserved{false}
      subject.defs[:foo] = mock!.reserved{true}.subject
      dont_allow(subject).store
      subject.reserve(tok).should be_nil
    end
    
    it "raises an error if the name has been defined but not reserved locally" do
      tok = Smithereen::LexerToken.new(:name, 'foo').extend Smithereen::TokenInstanceMethods
      mock(tok).reserved{false}
      subject.defs[:foo] = mock!.reserved{false}.subject
      dont_allow(subject).store
      lambda{subject.reserve(tok)}.should raise_error(Smithereen::ParseError, "Already defined: #{tok}")
    end
    
    it "stores the name as reserved if it hasn't been defined or reserved locally" do
      tok = Smithereen::LexerToken.new(:name, 'foo')
      mock(tok).reserved{false}
      mock(subject).store(tok, true){:some_module}
      subject.reserve(tok).should == :some_module
    end
  end
  
  describe "#pop" do
    it "sets the parser's scope to parent" do
      parser = Struct.new(:scope).new(:old_scope)
      Scope.new(parser, :parent_scope).pop
      parser.scope.should == :parent_scope
    end
  end
  
  describe "#store" do
    subject { Scope.new(Object.new, nil) }
    
    it "creates a new token module, returns it, and stores it as a local define" do
      tok = Smithereen::LexerToken.new(:name, 'some_name')
      mock(subject).new_binding_module(false){:mock_module}
      subject.send(:store, tok, false).should == :mock_module
      subject.defs[:some_name].should == :mock_module
    end
  end
  
  describe "#new_binding_module" do
    class MockGrammar < Smithereen::Grammar; end
    subject { Scope.new(Smithereen::Parser.new(MockGrammar.new, nil), nil) }
    
    it "returns a new token module (with type :name and 0 binding power)" do
      tok = Smithereen::LexerToken.new(:name, 'some_name')
      stub(mock_module = Object.new) do |allow|
        allow.module_eval
        allow.reserved = false
        allow.scope = subject
      end
      mock(mock_module).dup{mock_module}
      mock(subject.parser).symbol_table{ {:name => mock_module} }
      subject.send(:new_binding_module, false).should == mock_module
    end
    
    it "defines :reserved and :scope as accessors on the module" do
      tok = Smithereen::LexerToken.new(:name, 'some_name')
      mock(mock_module = Module.new).dup{mock_module}
      stub(subject).symbol_table{ {:name => mock_module} }
      result_module = subject.send(:new_binding_module, :reserved_val)
      result_module.should == mock_module
      result_module.reserved.should == :reserved_val
      result_module.scope.should == subject
    end
    
    it "sets 'module.reserved' based on the passed 'reserved' parameter" do
      tok = Smithereen::LexerToken.new(:name, 'some_name')
      mock(mock_module = Object.new).reserved = 'some_reserved_value'
      stub(mock_module) do |allow|
        allow.module_eval
        allow.scope = subject
      end
      mock(mock_module).dup{mock_module}
      mock(subject.parser).symbol_table{ {:name => mock_module} }
      subject.send(:new_binding_module, 'some_reserved_value')
    end        
    
    it "stores the scope object as the module's 'scope' value" do
      tok = Smithereen::LexerToken.new(:name, 'some_name')
      mock(mock_module = Object.new).scope = subject
      stub(mock_module) do |allow|
        allow.module_eval
        allow.reserved = false
      end
      mock(mock_module).dup{mock_module}
      mock(subject.parser).symbol_table{ {:name => mock_module} }
      subject.send(:new_binding_module, false)
    end
  end
end
