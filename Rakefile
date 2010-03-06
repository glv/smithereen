require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "radish"
    gem.summary = %Q{A library for building parsers using top-down operator precedence}
    gem.description = %Q{A library for building parsers using top-down operator precedence}
    gem.email = "glv@vanderburg.org"
    gem.homepage = "http://github.com/glv/radish"
    gem.authors = ["Glenn Vanderburg"]
    
    gem.add_runtime_dependency     "activesupport", ">= 3.0.0.beta1"
    
    gem.add_development_dependency "cucumber",      ">= 0.6.3"
    gem.add_development_dependency "jeweler",       ">= 1.4.0"
    gem.add_development_dependency "rr",            ">= 0.10.10"
    gem.add_development_dependency "rspec",         ">= 2.0.0.a7"
    gem.add_development_dependency "rcov",          ">= 0.9.8"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  require 'rspec/core/rake_task'
  namespace :spec do
    Rspec::Core::RakeTask.new(:examples) do |examples|
      examples.pattern = 'spec/**/*_spec.rb'
      examples.ruby_opts = '-Ilib -Ispec'
    end

    desc "Chooses documentation format for RSpec output"
    task :doc_format do |t|
      ENV['RSPEC_FORMATTER'] = 'documentation'
    end

    Rspec::Core::RakeTask.new(:rcov) do |examples|
      examples.pattern = 'spec/**/*_spec.rb'
      examples.rcov_opts = '-Ilib -Ispec -x "/.rvm/,/Library/Ruby/Gems,^spec/,rspec-dev"'
      examples.rcov = true
    end
  
    task :rcov => :doc_format
  end
rescue LoadError
  puts "RSpec 2 (or a dependency) not available. Install it with: gem install rspec --prerelease"
end

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

# task :examples => :check_dependencies

task :default => ['spec:examples', 'cucumber:progress']

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "radish #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
