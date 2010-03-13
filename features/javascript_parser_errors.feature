Feature: JavaScript Parser
  In order to demonstrate Radish
  As a programmer who sometimes makes weird mistakes 
  I want Simplified JavaScript Parser to have good syntax error messages
  
  Background:
    Given I have loaded the sample JavaScript parser
 
  Scenario Outline: Basic errors
    When I ask for the parse tree for expression "<input>"
    Then I should get the error "<message>"
    
    Examples:
      | input | message        |
      | + 2   | Unexpected '+' |
      | 2 +   | Unexpected end of input |
      | 2 3   | Unexpected number (3); expected '(end)' |
