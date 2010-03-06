Feature: Tiny Calculator
  In order to avoid silly mistakes
  As a math idiot 
  I want to have a calculator to run
  
  Background:
    Given I have loaded the sample calculator parser
 
  Scenario Outline: Run some calculations
    Given I ask the calculator for the answer to <input>
    Then I should see <result>
    
    Examples:
      | input          | result |
      | 24             |     24 |
      | 24 +2          |     26 |
      | 24 + 2 * 3     |     30 |
      | 24+2* - 3-12   |      6 |
      | 24+2*(-3-12)   |     -6 |
      | 24+2*-(3-12)   |     42 |
      | 24+2*-(3-12^2) |    306 |
      | 24+3*4/2 - 5   |     25 |
