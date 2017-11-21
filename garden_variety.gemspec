$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "garden_variety/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "garden_variety"
  s.version     = GardenVariety::VERSION
  s.authors     = [""]
  s.email       = [""]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of GardenVariety."
  s.description = "TODO: Description of GardenVariety."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "yard", "~> 0.9"
end
