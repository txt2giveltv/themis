source "https://rubygems.org"

# To test against different rails versions with TravisCI
rails_version = ENV['RAILS_VERSION'] || '3.2'

gem "rails", "~> #{rails_version}"

group :development, :test do
  gem 'rspec-rails', '~> 2.11'
  gem 'sqlite3'

  gem 'pry'
end

group :development do
  gem 'jeweler', '~> 1.8', :require => false
  gem 'yard'   ,           :require => false
end

group :test do
  gem 'simplecov', :require => false

  # To run specs against Rails 4.0, since +attr_accessible+ is used in specs.
  gem 'protected_attributes' if rails_version =~ /4\.\d/
end
