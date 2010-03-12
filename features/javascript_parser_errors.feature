Feature: JavaScript Parser
  In order to demonstrate Radish
  As a fan of Douglas Crockford's "Top-Down Operator Precedence" paper 
  I want a Radish version of his Simplified JavaScript Parser
  
  Background:
    Given I have loaded the sample JavaScript parser
 
  Scenario Outline: Basic errors
    When I ask for the parse tree for expression "<input>"
    Then I should get the error "<message>"
    
    Examples:
      | input | message        |
      | + 2   | Unexpected '+' |
