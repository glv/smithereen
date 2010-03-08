Feature: JavaScript Parser
  In order to demonstrate Radish
  As a fan of Douglas Crockford's "Top-Down Operator Precedence" paper 
  I want a Radish version of his Simplified JavaScript Parser
  
  Background:
    Given I have loaded the sample JavaScript parser
 
  Scenario Outline: Literals
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input | result       |
      | 2     | [:lit, 2   ] |
      | 3.14  | [:lit, 3.14] |
      | "a"   | [:lit, "a" ] |
      | 'a'   | [:lit, "a" ] |
      
  Scenario Outline: Unary operators
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                    |
      | - 2      | [:-,      [:lit, 2]     ] |
      | -3.14    | [:-,      [:lit, 3.14 ] ] |
      | ! 2      | [:'!',    [:lit, 2]     ] |
      | typeof 2 | [:typeof, [:lit, 2]     ] |
      
  Scenario Outline: Simple binary expressions
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input     | result                              |
      | 2 &&  2   | [:'&&',  [:lit, 2],   [:lit, 2]   ] |
      | 2 === 2   | [:===,   [:lit, 2],   [:lit, 2]   ] |
      | 2 !== 2   | [:'!==', [:lit, 2],   [:lit, 2]   ] |
      | 2 <   2   | [:<,     [:lit, 2],   [:lit, 2]   ] |
      | 2 <=  2   | [:<=,    [:lit, 2],   [:lit, 2]   ] |
      | 2 >   2   | [:>,     [:lit, 2],   [:lit, 2]   ] |
      | 2 >=  2   | [:>=,    [:lit, 2],   [:lit, 2]   ] |
      | 2 +   2   | [:+,     [:lit, 2],   [:lit, 2]   ] |
      | "a" + "b" | [:+,     [:lit, "a"], [:lit, "b"] ] |
      | 2 -   2   | [:-,     [:lit, 2],   [:lit, 2]   ] |
      | 2 *   2   | [:*,     [:lit, 2],   [:lit, 2]   ] |
      | 2 /   2   | [:/,     [:lit, 2],   [:lit, 2]   ] |
      
  # This one messes with Gherkin's example table syntax:
  Scenario: Binary || operator
    When I ask for the parse tree for "2 || 2"
    Then I should see the tree "[:'||', [:lit, 2], [:lit, 2]]"
      
  Scenario Outline: Mixed binary and unary operators
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                              |
      | 2 && - 2 | [:'&&', [:lit, 2], [:-, [:lit, 2]]] |
      | 2 >= - 2 | [:>=,   [:lit, 2], [:-, [:lit, 2]]] |
      | 2 +  - 2 | [:+,    [:lit, 2], [:-, [:lit, 2]]] |
      
  Scenario Outline: Binary operator precedence
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input       | result                                          |
      | 1 && 2 <  3 | [:'&&', [:lit, 1], [:<, [:lit, 2], [:lit, 3]] ] |
      | 1 >  2 && 3 | [:'&&', [:>, [:lit, 1], [:lit, 2]], [:lit, 3] ] |
      | 1 <  2 +  3 | [:<,    [:lit, 1], [:+, [:lit, 2], [:lit, 3]] ] |
      | 1 -  2 >  3 | [:>,    [:-, [:lit, 1], [:lit, 2]], [:lit, 3] ] |
      | 1 +  2 *  3 | [:+,    [:lit, 1], [:*, [:lit, 2], [:lit, 3]] ] |
      | 1 /  2 -  3 | [:-,    [:/, [:lit, 1], [:lit, 2]], [:lit, 3] ] |
      
  Scenario Outline: Ternary operator
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input        | result                                                   |
      | 1 ? 2 : 3    | [:'?', [:lit, 1], [:lit, 2], [:lit, 3] ]                 |
      | 1&&2 ? 3 : 4 | [:'?', [:'&&', [:lit,1], [:lit,2]], [:lit,3], [:lit,4] ] |
      | 1 ? 2&&3 : 4 | [:'?', [:lit,1], [:'&&', [:lit,2], [:lit,3]], [:lit,4] ] |
      | 1 ? 2 : 3&&4 | [:'?', [:lit,1], [:lit,2], [:'&&', [:lit,3], [:lit,4]] ] |
      
  Scenario Outline: Grouping with parentheses
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input       | result                                       |
      | (1 + 2) * 3 | [:*, [:+, [:lit, 1], [:lit, 2]], [:lit, 3] ] |
      | 1 / (2 - 3) | [:/, [:lit, 1], [:-, [:lit, 2], [:lit, 3]] ] |
      
  Scenario Outline: Arrays
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                          |
      | []       | [:array ]                       |
      | [ 2 ]    | [:array, [:lit, 2] ]            |
      | [ 2, 3 ] | [:array, [:lit, 2], [:lit, 3] ] |

  Scenario Outline: Objects
    When I ask for the parse tree for "<input>"
    Then I should see the tree "<result>"
    
    # TODO: need some with names as keys, when names are supported
    Examples:
      | input     | result                                        |
      | {}        | [:object ]                                    |
      | {"a": 2}  | [:object, [:keyval, [:lit, "a"], [:lit, 2]] ] |
      | {1:2,3:4} | [:object, [:keyval,[:lit,1],[:lit,2]], [:keyval,[:lit,3],[:lit,4]]] |