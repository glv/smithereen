Given /^I have loaded the sample calculator parser$/ do
  require File.dirname(__FILE__) + '/../../samples/calculator'
  @parser_class = SmithereenSamples::Calculator
end

Given /^I ask the calculator for the answer to "([^\"]*)"$/ do |input|
  # Gherkin doesn't process escape sequences in strings, so ask ruby to do that:
  calculator_input = eval(%{"#{input}"})
  begin
    @result = @parser_class.new(calculator_input).parse
    @syntax_error = nil
  rescue Smithereen::ParseError => e
    @result = nil
    @syntax_error = e
  end
end

Then /^I should see "([^\"]*)"$/ do |expected_result|
  @result.should == expected_result.to_i
end

Then /^I should get the error "([^\"]*)"$/ do |expected_message|
  @syntax_error.message.should match(Regexp.new("^#{Regexp.escape(expected_message)}: "))
end
