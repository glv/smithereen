require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/lexer'

describe Radish::Lexer do
  subject { Radish::Lexer.new("foo") }
  
  describe "newly created" do
    it "stores the source stream as @s" do
      subject.send(:s).should == "foo"
    end
    
    it "sets @i to 0" do
      subject.send(:i).should == 0
    end
    
    it "sets @length to the length of the source stream" do
      subject.send(:length).should == "foo".size
    end
  end
  
  describe "#take_token" do
    it "delegates to produce_next_token" do
      mock(subject).produce_next_token {:some_token}
      subject.take_token.should == :some_token
    end
  end
  
  describe "#move" do
    it "increments @i by the supplied incr value" do
      subject.send(:move, 2)
      subject.send(:i).should == 2
      subject.send(:move, 1)
      subject.send(:i).should == 3
    end
    
    it "uses 1 as the default incr value" do
      subject.send(:move)
      subject.send(:i).should == 1
      subject.send(:move)
      subject.send(:i).should == 2
    end
  end
  
  describe "#make_token" do
    it "creates a token with the supplied type and text" do
      tok = subject.send(:make_token, :foo, 'bar')
      tok.type.should == :foo
      tok.text.should == 'bar'
    end
    
    it "uses @i as the token's 'from' value" do
      subject.send(:i=, 2)
      tok = subject.send(:make_token, :foo, 'bar')
      tok.from.should == 2
    end
    
    it "sets the token's 'to' to 'from' plus the supplied 'size' value" do
      subject.send(:i=, 2)
      tok = subject.send(:make_token, :foo, 'bar', 3)
      tok.to.should == 5
    end
    
    it "uses 'text.size' as the default 'size' value" do
      tok = subject.send(:make_token, :foo, 'bar')
      tok.to.should == 3
    end
    
    it "moves @i by 'size'" do
      tok = subject.send(:make_token, :foo, 'bar', 8)
      subject.send(:i).should == 8
    end
  end

end
