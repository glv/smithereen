require File.dirname(__FILE__) + '/../spec_helper'

require 'smithereen/token'
require 'smithereen/errors'

describe Smithereen::TokenClassMethods do
  subject { Class.new.extend Smithereen::TokenClassMethods }
  
  describe "#defblock" do
    it "defines the requested instance method with the supplied block" do
      subject.send(:defblock, :foo) { 'bar' }
      subject.new.foo.should == 'bar'
    end
    
    it "undefs the method if no block is passed" do
      subject.new.respond_to?(:to_s).should be_true
      subject.send(:defblock, :to_s)
      subject.new.respond_to?(:to_s).should be_false
    end
  end
  
  describe "#to_s" do
    it "delegates to #to_msg" do
      mock(subject).to_msg{"some msg"}
      subject.to_s.should == "some msg"
    end
  end
  
  describe "#to_msg" do
    # This is a heuristic that should result in the correct default behavior
    # for most token types, but not all.
    
    it "returns the type alone if the type contains only word characters" do
      mock(subject).type{:foo}.times(any_times)
      subject.to_msg.should == "foo"
    end
    
    it "returns the type in single quotes if the type contains any non-word characters" do
      mock(subject).type{:'f+o'}.times(any_times)
      subject.to_msg.should == "'f+o'"
    end
  end
  
  describe "#prefix" do
    it "defines the :prefix method with the supplied block" do
      subject.send(:prefix) { 'bar' }
      subject.new.prefix.should == 'bar'
    end
  end
  
  describe "#infix" do
    it "defines the :infix method with the supplied block" do
      subject.send(:infix) {|left| 'bar' }
      subject.new.infix(1).should == 'bar'
    end
  end
end

describe Smithereen::TokenInstanceMethods do
  subject { Smithereen::LexerToken.new(:foo, 'bar').extend Smithereen::TokenInstanceMethods }
  
  describe "#prefix" do
    it "complains if called" do
      lambda{subject.prefix}.should raise_error(Smithereen::ParseError, "Unexpected #{subject.type} (#{subject.text}): #{subject}")
      operator_token = Smithereen::LexerToken.new(:+, '+').extend Smithereen::TokenInstanceMethods
      lambda{operator_token.prefix}.should raise_error(Smithereen::ParseError, "Unexpected '+': #{operator_token}")
    end
  end

  describe "#infix" do
    it "complains if called" do
      lambda{subject.infix(1)}.should raise_error(Smithereen::ParseError, "Unexpected #{subject.type} (#{subject.text}): #{subject}")
    end
  end
  
  describe "#method_missing" do
    it "delegates to parser if the parser supports the method" do
      mock(parser = Object.new) do |expect|
        expect.respond_to?(:foo){true}
        expect.foo(1, 2, :a => 3){:bar}
      end
      subject.parser = parser
      subject.foo(1, 2, :a => 3).should == :bar
    end
    
    it "calls super if the parser does not support the method" do
      mock(parser = Object.new).respond_to?(:foo){false}
      dont_allow(parser).foo(1)
      subject.parser = parser
      lambda{subject.foo(1)}.should raise_error(StandardError)
    end
  end
  
  describe "#advance_if_looking_at" do
    it "delegates to parser" do
      stub(subject).parser.mock!.advance_if_looking_at(:foo)
      subject.advance_if_looking_at(:foo)
    end
  end
  
  describe "#expression" do
    it "delegates to parser" do
      stub(subject).parser.mock!.expression(:foo)
      subject.expression(:foo)
    end
  end
  
  describe "#exception" do
    it "creates a ParseError with the passed message and the token" do
      error = subject.exception('some message')
      error.message.should == "some message: #{subject}"
      error.token.should == subject
    end
    
    it "uses 'Parse error' as the default message" do
      error = subject.exception
      error.message.should == "Parse error: #{subject}"
    end
  end
  
  describe "#to_msg" do
    it "returns just the token text if the type and text are the same" do
      tok = Smithereen::LexerToken.new(:+, '+').extend Smithereen::TokenInstanceMethods
      tok.to_msg.should == "'+'"
    end

    it "returns the token type and text if the type and text are different" do
      tok = Smithereen::LexerToken.new(:integer, '42').extend Smithereen::TokenInstanceMethods
      tok.to_msg.should == "integer (42)"
    end
  end
end

describe Smithereen::StatementTokenClassMethods do
  subject do
    Class.new do
      extend Smithereen::TokenClassMethods
      extend Smithereen::StatementTokenClassMethods 
    end
  end
  
  describe "#stmt" do
    it "defines the :stmt method with the supplied block" do
      subject.send(:stmt) { 'bar' }
      subject.new.stmt.should == 'bar'
    end
  end
end
