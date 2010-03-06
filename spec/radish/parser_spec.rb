require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/parser'

describe Radish::Parser do
  Parser = Radish::Parser
  
  describe "::inherited" do
    it "defines the (end) token in a new subclass's symbol table" do
      c = Class.new(Parser)
      c.symbol_table[Parser::END_TOKEN_TYPE].should be_a(Module)
    end
  end
end
