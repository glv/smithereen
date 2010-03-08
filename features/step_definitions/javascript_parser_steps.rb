Given /^I have loaded the sample JavaScript parser$/ do
  require File.dirname(__FILE__) + '/../../samples/simplified_javascript/javascript_lexer'
  require File.dirname(__FILE__) + '/../../samples/simplified_javascript/javascript_parser'
  @lexer_class  = RadishSamples::SimplifiedJavaScriptLexer
  @parser_class = RadishSamples::SimplifiedJavaScriptParser
end

When /^I ask for the parse tree for "(.*)"$/ do |js_source|
  parser = @parser_class.new(@lexer_class.new(js_source))
  @result = parser.parse
end

Then /^I should see the tree "(.*)"$/ do |expected_tree_string|
  @result.should == eval(expected_tree_string)
end

