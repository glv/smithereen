require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
desc "Run all examples"
RSpec::Core::RakeTask.new(:spec)

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = %w{--format pretty}
  end

  namespace :cucumber do 
    Cucumber::Rake::Task.new(:progress) do |t|
      t.cucumber_opts = %w{--format progress}
    end
  end
rescue LoadError
  puts "Cucumber (or a dependency) not available. Install it with: gem install cucumber"
end

task :default => ['spec', 'cucumber:progress']
