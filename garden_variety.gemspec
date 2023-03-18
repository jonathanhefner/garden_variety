require_relative "lib/garden_variety/version"

Gem::Specification.new do |spec|
  spec.name        = "garden_variety"
  spec.version     = GardenVariety::VERSION
  spec.authors     = ["Jonathan Hefner"]
  spec.email       = ["jonathan@hefner.pro"]
  spec.homepage    = "https://github.com/jonathanhefner/garden_variety"
  spec.summary     = %q{Delightfully boring Rails controllers}
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.metadata["source_code_uri"] + "/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "rails", ">= 6.1"
  spec.add_dependency "pundit", "~> 2.0"
end
