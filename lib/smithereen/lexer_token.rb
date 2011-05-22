require 'smithereen/errors'

module Smithereen
  LexerToken = Struct.new(:type, :text, :from, :to)
end
