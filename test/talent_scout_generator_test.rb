return if Bundler.load.dependencies.none?{|dep| dep.name == "talent_scout" }
require "test_helper"
require_relative "generator_test_case"
require "generators/garden/scaffold/scaffold_generator"

class TalentScoutGeneratorTest < GeneratorTestCase
  tests Garden::Generators::ScaffoldGenerator

  def setup
    Bundler.load.setup(:default, :talent_scout)
    assert require "talent_scout"
    super
  end

  def test_generates_talent_scout_search
    run_generator(["spaced/fruit"])
    assert_file "app/models/spaced/fruit.rb" # sanity check
    assert_file "app/searches/spaced/fruit_search.rb"
  end

  def test_respects_skip_talent_scout
    run_generator(["vegetable", "--skip-talent-scout"])
    assert_file "app/models/vegetable.rb" # sanity check
    assert_no_directory "app/searches"
  end

end
