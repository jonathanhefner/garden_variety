require "test_helper"
require_relative "generator_test_case"
require "generators/garden/install/install_generator"

class InstallGeneratorTest < GeneratorTestCase
  tests Garden::Generators::InstallGenerator

  test "generates flash locales" do
    run_generator
    assert_file "config/locales/flash.en.yml"
  end

  test "generates Pundit ApplicationPolicy if missing" do
    policy_file = "app/policies/application_policy.rb"
    assert_no_file policy_file # sanity check

    run_generator
    assert_file policy_file

    File.write(File.join(destination_root, policy_file), "EXPECTED")

    run_generator
    assert_file policy_file, "EXPECTED"
  end
end
