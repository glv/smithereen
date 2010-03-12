begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  puts "Something's wrong with bundle configuration.  Falling back to RubyGems."
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'rspec'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'radish'

def in_editor?
  ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM')
end

Rspec.configure do |c|
  c.mock_framework = :rr
  c.filter_run :focused => true
  c.run_all_when_everything_filtered = true
  c.color_enabled = !in_editor?
  c.alias_example_to :fit, :focused => true
  c.profile_examples = false
  if ENV['RUN_CODE_RUN'] == 'true'
    c.formatter = :documentation
  elsif ENV['RSPEC_FORMATTER']
    c.formatter = ENV['RSPEC_FORMATTER']
  end
  c.include(CustomRadishMatchers)
end
