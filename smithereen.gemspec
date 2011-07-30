# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "smithereen/version"

Gem::Specification.new do |s|
  s.name = 'smithereen'
  s.version = Smithereen::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Glenn Vanderburg"]
  s.email       = ["glv@vanderburg.org"]
  s.homepage    = 'http://github.com/glv/smithereen'
  s.summary     = %q{A library for building parsers using top-down operator precedence}
  s.description = %q{A library for building parsers using top-down operator precedence}

  s.rubyforge_project = "smithereen"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  #s.required_ruby_version = '>= 1.9.2'

  add_runtime_dependency = if s.respond_to?(:specification_version) && Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
                             :add_runtime_dependency
                           else
                             :add_dependency
                           end
  s.send(add_runtime_dependency, 'activesupport', ['~> 3.0'])

  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rcov'
  s.add_development_dependency 'rr'
  s.add_development_dependency 'rspec', ['~> 2.0']
end
