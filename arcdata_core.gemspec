$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "arcdata_core"
  s.version     = Core::VERSION
  s.authors     = ["John Laxson"]
  s.email       = ["john.laxson@redcross.org"]
  s.homepage    = "http://github.com/redcross/core"
  s.summary     = "Common components of the Arcdata applications."
  s.description = "Common components of the Arcdata applications."
  s.license     = ""

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 6.0"
  s.add_dependency "activeadmin", "2.7.0"
end
