require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/token'
require 'radish/errors'

describe Radish::TokenClassMethods do
  subject { Class.new.extend Radish::TokenClassMethods }
  
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
  
  describe "#prefix" do
    it "defines the :prefix method with the supplied block" do
      subject.send(:prefix) { 'bar' }
      subject.new.prefix.should == 'bar'
    end
    
    it "rejects blocks with positive arities" do
      lambda{subject.send(:prefix) {|a| 1}}.should raise_error(Radish::GrammarError)
    end
  end
  
  describe "#infix" do
    it "defines the :infix method with the supplied block" do
      subject.send(:infix) {|left| 'bar' }
      subject.new.infix(1).should == 'bar'
    end
    
    it "rejects blocks unless the arity is 1 or negative" do
      lambda{subject.send(:infix) {1}}.should_not raise_error
      lambda{subject.send(:infix) {|a,b| 1}}.should raise_error(Radish::GrammarError)
    end
  end
end

describe Radish::TokenInstanceMethods do
  subject { Object.new.extend Radish::TokenInstanceMethods }
  
  describe "#prefix" do
    it "complains if called" do
      lambda{subject.prefix}.should raise_error(Radish::ParseError)
    end
  end

  describe "#infix" do
    it "complains if called" do
      lambda{subject.infix(1)}.should raise_error(Radish::ParseError)
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

    it "delegates to parser with default lbp of 0" do
      stub(subject).parser.mock!.expression(0)
      subject.expression
    end
  end
end
