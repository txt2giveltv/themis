require 'rubygems'

# Configure Rails Envinronment
ENV["RAILS_ENV"] ||= "test"

# Use pry and run SimpleCov if it's Ruby1.9
if RUBY_VERSION =~ /^1\.9/
  require 'pry'
  require 'simplecov'
  SimpleCov.start
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/autorun'
require 'rspec/rails'

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
end
