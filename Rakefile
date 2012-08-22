#!/usr/bin/env rake

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'themis/version'

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end


def gemspec
  @gem_spec ||= eval( open( `ls *.gemspec`.strip ){|file| file.read } )
end

def gem_version
  gemspec.version
end

def gem_version_tag
  "v#{gem_version}"
end

def gem_name
  gemspec.name
end

def gem_file_name
  "#{gem_name}-#{gem_version}.gem"
end

namespace :gemfury do
  desc "Build version #{gem_version} into the pkg directory and upload to GemFury"
  task :push => [:build] do
    sh "fury push pkg/#{gem_file_name} --as=TMXCredit"
  end
end


require "jeweler"
Jeweler::Tasks.new do |gem|
  gem.name        = "themis"
  gem.summary     = "Flexible and modular validations for ActiveRecord models"
  gem.description = "Flexible and modular validations for ActiveRecord models"
  gem.email       = ["blake131313@gmail.com"]
  gem.authors     = ['Potapov Sergey']
  gem.files       = Dir["{app,config,db,lib}/**/*"] + Dir['Rakefie', 'README.markdown']
  gem.version     = Themis::VERSION
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

#Rake::Task[:spec].enhance ['db:setup']

task :default => :spec
