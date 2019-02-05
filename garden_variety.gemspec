$:.push File.expand_path("../lib", __FILE__)

require "garden_variety/version"

Gem::Specification.new do |s|
  s.name        = "garden_variety"
  s.version     = GardenVariety::VERSION
  s.authors     = ["Jonathan Hefner"]
  s.email       = ["jonathan.hefner@gmail.com"]
  s.homepage    = "https://github.com/jonathanhefner/garden_variety"
  s.summary     = %q{Delightfully boring Rails controllers}
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.1"
  s.add_dependency "pundit", "~> 2.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "yard", "~> 0.9"
  s.add_development_dependency "talent_scout" # see Gemfile for version
end
