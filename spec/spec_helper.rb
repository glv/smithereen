require 'rubygems'

require File.dirname(__FILE__) + '/../rspec-dev-setup' if File.exists?(File.dirname(__FILE__) + '/../rspec-dev-setup.rb')

require 'rspec'
gem 'rr'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

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
  c.formatter = :documentation # if ENV["RUN_CODE_RUN"] == "true"
  c.include(CustomRadishMatchers)
end
