source "https://rubygems.org"

# To test against different rails versions with TravisCI
rails_version = ENV['RAILS_VERSION'] || '>= 3.1'

gem "rails", "#{rails_version}"

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'sqlite3'

  gem 'pry'
end

group :development do
  gem 'jeweler', :require => false
  gem 'yard'   , :require => false
end

group :test do
  gem 'simplecov', :require => false
end
