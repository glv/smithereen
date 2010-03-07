Feature: JavaScript Parser
  In order to demonstrate Radish
  As a fan of Douglas Crockford's "Top-Down Operator Precedence" paper 
  I want a Radish version of his Simplified JavaScript Parser
  
  Background:
    Given I have loaded the sample JavaScript parser
 
  Scenario Outline: Parse some expressions
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input          | result                     |
      | 24             | [:lit, 24]                 |
      | 2 + 2          | [:+, [:lit, 2], [:lit, 2]] |
