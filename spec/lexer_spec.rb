require File.dirname(__FILE__) + '/spec_helper'

require 'radish/lexer'

describe Radish::Lexer do
  describe "whitespace and end-of-stream processing" do
    it "returns an :(end) token for an empty source" do
      l = Radish::Lexer.new('')
      l.take_token.should be_nil
    end
    
    it "skips over whitespace and returns an :(end) token for a blank source" do
      l = Radish::Lexer.new(" \t \n \r \r\n \t  ")
      l.take_token.should be_nil
    end
  end
  
  describe "integers" do
    it "recognizes an integer as the content of the stream" do
      l = Radish::Lexer.new('42')
      l.take_token.should be_lexer_token(:integer, '42', 0, 2)
      l.take_token.should be_nil
    end
    
    it "recognizes an integer as the first thing in the stream" do
      l = Radish::Lexer.new('42   ')
      l.take_token.should be_lexer_token(:integer, '42', 0, 2)
      l.take_token.should be_nil
    end
    
    it "recognizes an integer after some whitespace" do
      l = Radish::Lexer.new('  42   ')
      l.take_token.should be_lexer_token(:integer, '42', 2, 4)
      l.take_token.should be_nil
    end
  end
  
  describe "+ operator" do
    it "recognizes + as the content of the stream" do
      l = Radish::Lexer.new('+')
      l.take_token.should be_lexer_token(:+, '+', 0, 1)
      l.take_token.should be_nil
    end
  end
  
  describe "expressions" do
    it "produces the proper tokens for a simple addition expression" do
      l = Radish::Lexer.new('  42   +18')
      l.take_token.should be_lexer_token(:integer, '42')
      l.take_token.should be_lexer_token(:+, '+')
      l.take_token.should be_lexer_token(:integer, '18') 
      l.take_token.should be_nil
    end
  end
end
