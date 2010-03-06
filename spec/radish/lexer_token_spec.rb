require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/lexer_token'
require 'radish/errors'

describe Radish::LexerToken do
  subject { Radish::LexerToken.new(:foo, 'bar', 3, 6) }
  
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
  
end
