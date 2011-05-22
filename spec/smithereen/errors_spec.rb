require File.dirname(__FILE__) + '/../spec_helper'

require 'smithereen/errors'

describe Smithereen::ParseError do  
  describe "#initialize" do
    it "passes the message to super and stores the token" do
      error = Smithereen::ParseError.new("foo", :bar)
      error.message.should == "foo: #{:bar}"
    end
  end
end
