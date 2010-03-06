require File.dirname(__FILE__) + '/../spec_helper'

require 'radish/errors'

describe Radish::ParseError do  
  describe "#initialize" do
    it "passes the message to super and stores the token" do
      error = Radish::ParseError.new("foo", :bar)
      error.message.should == "foo: #{:bar}"
    end
  end
end
