$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "themis/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "themis"
  s.version     = Themis::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Themis."
  s.description = "TODO: Description of Themis."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.8"

  s.add_development_dependency "sqlite3"
end
