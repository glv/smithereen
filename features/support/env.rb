require 'rspec/expectations'

class RspecWorld
  include Rspec::Expectations
  include Rspec::Matchers
end

World do
  RspecWorld.new
end
