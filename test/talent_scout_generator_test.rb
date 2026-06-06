return if Bundler.load.dependencies.none?{|dep| dep.name == "talent_scout" }
require "test_helper"
require_relative "generator_test_case"
require "generators/garden/scaffold/scaffold_generator"

class TalentScoutGeneratorTest < GeneratorTestCase
  include ActiveSupport::Testing::Isolation
  tests Garden::Generators::ScaffoldGenerator

  def setup
    Bundler.load.setup(:default, :talent_scout)
    assert require "talent_scout"

    self.class.destination "#{destination_root}/#{Process.pid}"
    super
    prepare_routes
  end

  test "generates a talent_scout model search class" do
    run_generator(["spaced/fruit"])
    assert_file "app/models/spaced/fruit.rb" # sanity check
    assert_file "app/searches/spaced/fruit_search.rb"
  end

  test "respects --skip-talent-scout" do
    run_generator(["vegetable", "--skip-talent-scout"])
    assert_file "app/models/vegetable.rb" # sanity check
    assert_no_directory "app/searches"
  end

end
