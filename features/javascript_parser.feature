Feature: JavaScript Parser
  In order to demonstrate Radish
  As a fan of Douglas Crockford's "Top-Down Operator Precedence" paper 
  I want a Radish version of his Simplified JavaScript Parser
  
  Background:
    Given I have loaded the sample JavaScript parser
 
  Scenario Outline: Parse some expressions
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    # At present, I'm expecting the tree to come back in the format
    # returned by passing a similar expression through Ruby's 
    # ParseTree.translate method.  That's not ideal, because it
    # doesn't match the tree format of Crockford's parser *at* *all*,
    # and because when I get past simple mathematical expressions, 
    # the Ruby and JavaScript grammars diverge pretty quickly.
    Examples:
      | input          | result                                      |
      | 24             | [:lit, 24]                                  |
      | 2 + 2          | [:call, [:lit, 2], :+, [:array, [:lit, 2]]] |
