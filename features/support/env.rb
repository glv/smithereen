begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'rspec/expectations'

class RspecWorld
  include Rspec::Expectations
  include Rspec::Matchers
end

World do
  RspecWorld.new
end
