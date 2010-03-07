require 'radish/errors'

module Radish
  LexerToken = Struct.new(:type, :text, :from, :to)
end
