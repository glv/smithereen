require 'rspec/expectations'

class RSpecWorld
  include RSpec::Expectations
  include RSpec::Matchers
end

World do
  RSpecWorld.new
end
