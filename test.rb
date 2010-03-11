#!/usr/bin/env ruby
require 'rubygems'
$: << 'lib'
$: << 'samples'
require 'simplified_javascript/javascript_lexer'
require 'simplified_javascript/javascript_parser'

lexer = RadishSamples::SimplifiedJavaScriptLexer.new('var a;')
parser = RadishSamples::SimplifiedJavaScriptParser.new(lexer)

parser.parse_statement
