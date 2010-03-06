require 'rubygems'
require 'rake'

# begin
#   require 'jeweler'
#   Jeweler::Tasks.new do |gem|
#     gem.name = "radish"
#     gem.summary = %Q{TODO: one-line summary of your gem}
#     gem.description = %Q{TODO: longer description of your gem}
#     gem.email = "glv@vanderburg.org"
#     gem.homepage = "http://github.com/glv/radish"
#     gem.authors = ["Glenn Vanderburg"]
#     gem.add_development_dependency "rspec", ">= 2"
#     # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
#   end
#   Jeweler::GemcutterTasks.new
# rescue LoadError
#   puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
# end

require 'rspec/core/rake_task'
Rspec::Core::RakeTask.new(:examples) do |examples|
  examples.pattern = 'spec/**/*_spec.rb'
  examples.ruby_opts = '-Ilib -Ispec'
end

Rspec::Core::RakeTask.new(:rcov) do |examples|
  examples.pattern = 'spec/**/*_spec.rb'
  examples.rcov_opts = '-Ilib -Ispec -x "/.rvm/,/Library/Ruby/Gems,^spec/,rspec-dev"'
  examples.rcov = true
end

# task :examples => :check_dependencies

task :default => :examples

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "radish #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
