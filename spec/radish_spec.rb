require File.dirname(__FILE__) + '/spec_helper'

describe "Radish lexical analysis" do
  it "recognizes integers" do
    def token(string)
      string[/^\d+/]
    end
    token("3").should == "3"
  end
  
  it "recognizes integers with embedded underscores" do
    def token(string)
      string[/^\d([\d_]*\d)?/]
    end
    token("3_4").should == "3_4"
    token("_34").should == nil
    token("34_").should == "34"
  end
end
