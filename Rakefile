require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "param_protected"
    gemspec.summary = "Filter unwanted parameters in your controllers and actions."
    gemspec.description = "Provides two class methods on ActiveController::Base that filter the params hash for that controller's actions.  You can think of them as the controller analog of attr_protected and attr_accessible."
    gemspec.email = "cjbottaro@alumni.cs.utexas.edu"
    gemspec.homepage = "http://github.com/cjbottaro/param_protected"
    gemspec.authors = ["Christopher J. Bottaro"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the param_protected plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the param_protected plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ParamProtected'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
