Given /^I have loaded the sample JavaScript parser$/ do
  require File.dirname(__FILE__) + '/../../samples/simplified_javascript/javascript_lexer'
  require File.dirname(__FILE__) + '/../../samples/simplified_javascript/javascript_parser'
  @lexer_class  = RadishSamples::SimplifiedJavaScriptLexer
  @parser_class = RadishSamples::SimplifiedJavaScriptParser
end

When /^I define the name "([^\"]*)"$/ do |name|
  @names_to_define ||= []
  @names_to_define << name
end

When /^I ask for the parse tree for (\w+) "(.*)"$/ do |construct_type, js_source|
  parser = @parser_class.new(@lexer_class.new(js_source))
  (@names_to_define||[]).each{|name| parser.scope.define(Radish::LexerToken.new(:name, name))}
  
  begin
    @result = case construct_type
              when 'expression' then parser.parse_expression
              when 'statement'  then parser.parse_statement
              else                   raise "Unrecognized construct type: #{construct_type}"
              end
    @syntax_error = nil
  rescue Radish::ParseError => e
    @result = nil
    @syntax_error = e
  end
end

Then /^I should see the tree "(.*)"$/ do |expected_tree_string|
  if @syntax_error
    fail "Expected a parse tree, got exception #{@syntax_error} instead:\n#{@syntax_error.backtrace*"\n"}"
  end
  @result.should == eval(expected_tree_string)
end

