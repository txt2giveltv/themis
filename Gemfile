source "http://rubygems.org"

def ruby19?; RUBY_VERSION =~ /^1\.9/ ; end
def ruby18?; RUBY_VERSION =~ /^1\.8/ ; end

gem "rails", "~> 3.0"

group :development, :test do
  gem 'jeweler'    , '~> 1.8'
  gem 'yard'

  gem 'rspec-rails', '~> 2.11'
  gem 'sqlite3'

  gem 'ruby-debug' if ruby18?
  gem 'pry'        if ruby19?
end

group :test do
  gem 'simplecov', :require => false if ruby19?
end
