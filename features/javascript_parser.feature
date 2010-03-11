Feature: JavaScript Parser
  In order to demonstrate Radish
  As a fan of Douglas Crockford's "Top-Down Operator Precedence" paper 
  I want a Radish version of his Simplified JavaScript Parser
  
  Background:
    Given I have loaded the sample JavaScript parser
 
  Scenario Outline: Literals
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input | result                    |
      | 2     | [:lit, 2   ]              |
      | 3.14  | [:lit, 3.14]              |
      | "a"   | [:lit, "a" ]              |
      | 'a'   | [:lit, "a" ]              |
      | true  | [:lit, true]              |
      | false | [:lit, false]             |
      | null  | [:lit, nil]               |
      | pi    | [:lit, 3.141592653589793] |
      
  Scenario Outline: Unary operators
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                    |
      | - 2      | [:-,      [:lit, 2]     ] |
      | -3.14    | [:-,      [:lit, 3.14 ] ] |
      | ! 2      | [:'!',    [:lit, 2]     ] |
      | typeof 2 | [:typeof, [:lit, 2]     ] |
      
  Scenario Outline: Simple binary expressions
    When I ask for the parse tree for expression "<input>"
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
      
  # TODO: These should fail unless a is defined, no?
  Scenario Outline: Assignments
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                                                                          |
      | a=3      | [:assignment, :'=', [:name, "a"], [:lit, 3]]                                    |
      | a+=3     | [:assignment, :'+=', [:name, "a"], [:lit, 3]]                                   |
      | a-=3     | [:assignment, :'-=', [:name, "a"], [:lit, 3]]                                   |
      | a-=b?0:1 | [:assignment, :'-=', [:name, "a"], [:'?', [:name, "b"], [:lit, 0], [:lit, 1]] ] |

  # TODO: These should fail unless a is defined, no?
  Scenario Outline: Terminated binary expressions
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                                                          |
      | a.b      | [:propref, [:name, "a"], [:name, "b"] ]                         |
      | a["b"]   | [:lookup, [:name, "a"], [:lit, "b"] ]                           |
      | a[1]     | [:lookup, [:name, "a"], [:lit, 1] ]                             |
      | a[2+3]   | [:lookup, [:name, "a"], [:+, [:lit, 2], [:lit, 3]] ]            |
      | a()      | [:call, [:name, "a"], [] ]                                      |
      | a(1)     | [:call, [:name, "a"], [[:lit, 1]] ]                             |
      | a(1,2)   | [:call, [:name, "a"], [[:lit, 1], [:lit, 2]] ]                  |
      | a(1,2+3) | [:call, [:name, "a"], [[:lit, 1], [:+, [:lit, 2], [:lit, 3]]] ] |
      | a.b()    | [:call, [:propref, [:name, "a"], [:name, "b"]], [] ]            |
      | a.b(2)   | [:call, [:propref, [:name, "a"], [:name, "b"]], [[:lit, 2]] ]   |
      | a[1]()   | [:call, [:lookup, [:name, "a"], [:lit, 1]], [] ]                |
      | a()()    | [:call, [:call, [:name, "a"], []], []]                          |
      # TODO: (function(){})()
      # TODO: function(){}() (should be an error, I think)
      
  # This one messes with Gherkin's example table syntax:
  Scenario: Binary || operator
    When I ask for the parse tree for expression "2 || 2"
    Then I should see the tree "[:'||', [:lit, 2], [:lit, 2]]"
      
  Scenario Outline: Mixed binary and unary operators
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                              |
      | 2 && - 2 | [:'&&', [:lit, 2], [:-, [:lit, 2]]] |
      | 2 >= - 2 | [:>=,   [:lit, 2], [:-, [:lit, 2]]] |
      | 2 +  - 2 | [:+,    [:lit, 2], [:-, [:lit, 2]]] |
      
  Scenario Outline: Binary operator precedence
    When I ask for the parse tree for expression "<input>"
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
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input        | result                                                   |
      | 1 ? 2 : 3    | [:'?', [:lit, 1], [:lit, 2], [:lit, 3] ]                 |
      | 1&&2 ? 3 : 4 | [:'?', [:'&&', [:lit,1], [:lit,2]], [:lit,3], [:lit,4] ] |
      | 1 ? 2&&3 : 4 | [:'?', [:lit,1], [:'&&', [:lit,2], [:lit,3]], [:lit,4] ] |
      | 1 ? 2 : 3&&4 | [:'?', [:lit,1], [:lit,2], [:'&&', [:lit,3], [:lit,4]] ] |
      
  Scenario Outline: Grouping with parentheses
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input       | result                                       |
      | (1 + 2) * 3 | [:*, [:+, [:lit, 1], [:lit, 2]], [:lit, 3] ] |
      | 1 / (2 - 3) | [:/, [:lit, 1], [:-, [:lit, 2], [:lit, 3]] ] |
      
  Scenario Outline: Arrays
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input    | result                          |
      | []       | [:array ]                       |
      | [ 2 ]    | [:array, [:lit, 2] ]            |
      | [ 2, 3 ] | [:array, [:lit, 2], [:lit, 3] ] |

  Scenario Outline: Objects
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    # TODO: need some with names as keys, when names are supported
    Examples:
      | input     | result                                                 |
      | {}        | [:object ]                                             |
      | {"a": 2}  | [:object, [:lit, "a"], [:lit, 2] ]                     |
      | {1:2,3:4} | [:object, [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4] ] |

  Scenario Outline: Functions
    When I ask for the parse tree for expression "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input               | result                                                               |
      | function(){}        | [:function, nil, [], [] ]                                            |
      | function a(){}      | [:function, [:name, "a"], [], []]                                    |
      | function a(b){c();} | [:function, [:name,"a"], [[:name,"b"]], [[:call, [:name,"c"], []]] ] |

  Scenario Outline: Simple statements
    When I ask for the parse tree for statement "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input          | result                                                          |
      | {break;}       | [:block, [:break ] ]                                            |
      | {return;}      | [:block, [:return] ]                                            |
      | {return 2;}    | [:block, [:return, [:lit, 2]] ]                                 |
      | {return this;} | [:block, [:return, [:name, "this"]] ]                           |
      | a = 3;         | [:assignment, :'=', [:name, "a"], [:lit, 3] ]                   |
      | {}             | [:block ]                                                       |
      | {a();}         | [:block, [:call, [:name, "a"], []] ]                            |
      | {a();b();}     | [:block, [:call, [:name, "a"], []], [:call, [:name, "b"], []] ] |

  Scenario Outline: Variable declarations
    When I ask for the parse tree for statement "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input        | result                                                              |
      | var a;       | [:var, [[:name, "a"]] ]                                             |
      | var a,b;     | [:var, [[:name, "a"]], [[:name, "b"]] ]                             |
      | var a=1;     | [:var, [[:name, "a"], [:lit, 1]] ]                                  |
      | var a=1,b;   | [:var, [[:name, "a"], [:lit, 1]], [[:name, "b"]] ]                  |
      | var a,b=1;   | [:var, [[:name, "a"]], [[:name, "b"], [:lit, 1]] ]                  |
      | var a=1,b=2; | [:var, [[:name, "a"], [:lit, 1]], [[:name, "b"], [:lit, 2]] ]       |
      | var a=1+2;   | [:var, [[:name, "a"], [:+, [:lit, 1], [:lit, 2]]] ]                 |
      | var a=1+2,b; | [:var, [[:name, "a"], [:+, [:lit, 1], [:lit, 2]]], [[:name, "b"]] ] |

  Scenario Outline: Other statements
    When I ask for the parse tree for statement "<input>"
    Then I should see the tree "<result>"
    
    Examples:
      | input        | result                                                                |
      | while(1){a();} | [:while, [:lit, 1], [:block, [:call, [:name, "a"], []]] ]           |
      | if(1){a();} | [:if, [:lit, 1], [:block, [:call, [:name, "a"], []]] ]                 |
      | if(1){}else{a();} | [:if, [:lit, 1], [:block], [:block, [:call, [:name, "a"], []]] ] |
      | if(1){}else if(2){} | [:if, [:lit, 1], [:block], [:if, [:lit, 2], [:block]] ]        |
