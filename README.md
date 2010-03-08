# radish

Radish is a library for building Top-Down Operator Precedence parsers.

To learn more about TDOP parsing, see
[Doug Crockford's chapter][crockford] in the book
<cite>[Beautiful Code][bc]</cite>, and
[Vaughan Pratt's original paper][pratt].

If you're already familiar with TDOP, you will notice that I'm using
nonstandard names for the methods that Pratt called "nud" and "led".
Part of my goal in writing this library was to understand the
algorithm better, and to make it easier for others to understand.
I found that Pratt's names were a barrier to understanding, so I'm
using "prefix" and "infix" instead (although I still think there
are better names out there waiting to be discovered).

## Rationale

I was intrigued when I read Crockford's chapter in <cite>Beautiful
Code</cite>.  It seemed to me that top-down operator precedence
promised parsers as easy to write and understand as recursive
descent, but with much better performance and space-efficiency.
Also, as a Rubyist, I was drawn by Crockford's claim that TDOP "is
most effective when used in a dynamic, functional programming
language." He goes on to say that TDOP:

> wants a dynamic language, but dynamic language communities
> historically have had no use for the syntax that Pratt's technique
> conveniently realizes.

Clearly, if ever there was a counterexample to that trend, it's the
Ruby community.

At the same time, I found it hard to grasp the core of the algorithm
from the code in Crockford's chapter (which is a parser for a
simplified dialect of JavaScript, written in that same dialect).
After some reflection, I realized that there were three problems
with that code:

1. The parts that are core to TDOP aren't clearly separated from
   the parts that are specific to parsing JavaScript.
2. JavaScript as an implementation language is *so* dynamic that
   the dynamic features TDOP exploits don't stand out.
3. Many of the important method names (most of which originated
   with Pratt) are poor, hindering understanding to someone who
   does not already grasp the algorithm.
   
A [Python implementation][python] by Fredrik Lundh is easier to
follow simply because he starts small and builds up the pieces
bit-by-bit, rather than presenting a full parser for a complex
grammar right from the start.  But of course the Python style of
implementation differs in many respects from what you would expect
to see in Ruby.

After some time, then, I decided to write a new implementation in
Ruby.  The goal is to provide a reusable core that can be exploited
by multiple different parsers, thus answering the first problem
with Crockford's implementation.  Ruby supports the same kinds of
dynamic features that JavaScript does, but their use is often more
explicit, which helps with the second problem.  And as I've grown
to understand the algorithm more, I've chosen different names and
done some refactoring to address the third.

In truth, the core of TDOP is very small, and there's simply *not*
a lot there that is independent of particular grammars.  However,
I've tried to provide a well-factored set of tools to help with the
core TDOP algorithm and several related problems, including scope,
symbol-table management, tree building, block structure, and the
distinction between expression- and statement-oriented languages.

## Design

Radish has one distinctive design characteristic, the full implications
of which are still unclear.  It may have to be changed if it proves
to have too great a performance impact.

One interesting characteristic of TDOP in an object-oriented language
is that it makes sense for tokens to actively participate in the
parsing process: tokens parse their own subexpressions.

A naive implementation of that, however, results in very tight
coupling of lexer and parser.  Crockford's implementation avoids
that by having the parser augment tokens, adding new methods to
them when they are received from the lexer.  That's a very JavaScript-y
solution that nicely demonstrates part of Crockford's point about
dynamic languages' natural affinity for TDOP.

It seemed to me that the best way to deal with this in Ruby was for
the parser to extend tokens with modules.  So a Radish parser's
symbol table contains a module for each token type, and the parser
calls `token.extend(token_module)` as each token is received from
the lexer.

I like that design, but it's unusual even in Ruby for such things
to be done in the inner loop of an algorithm that strives to perform
well.  I plan to do some profiling to assess the performance of
this design before committing to it for the long term.

## To do

* Set up bundler and get this running on RCR.
* Finish porting the sample JavaScript parser from Crockford's
  paper.
* Add some kind of tracing output to make it easier to understand
  (and debug) the algorithm.
* Reusable example groups for lexers and lexer tokens.
* Reconsider whether to hide the `left` parameter to `infix`.
* Names to reconsider: prefix, infix, extend_with_infixes, symbolize,
  symbol_module, lexer token, take_token, deftoken.
* Add notes and stats rake tasks.
* Measure performance:
  * speed
  * space
  * stack depth

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with Rakefile, VERSION, or history.
  (if you want to have your own version, that is fine but bump version in a commit
  by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2009, 2010 Glenn Vanderburg. See LICENSE for details.

[crockford]: http://javascript.crockford.com/tdop/tdop.html
[bc]: http://oreilly.com/catalog/9780596510046
[pratt]: http://portal.acm.org/citation.cfm?id=512931
[python]: http://effbot.org/zone/simple-top-down-parsing.htm
