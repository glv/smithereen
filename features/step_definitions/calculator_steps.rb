Given /^I have loaded the sample calculator parser$/ do
  require File.dirname(__FILE__) + '/../../samples/calculator'
  @parser_class = RadishSamples::Calculator
end

Given /^I ask the calculator for the answer to (.+)$/ do |input|
  @result = @parser_class.new(input).parse
end

Then /^I should see (.+)$/ do |expected_result|
  @result.should == expected_result.to_i
end
