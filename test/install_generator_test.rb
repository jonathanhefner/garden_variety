require "test_helper"
require_relative "generator_test_case"
require "generators/garden/install/install_generator"

class InstallGeneratorTest < GeneratorTestCase
  tests Garden::Generators::InstallGenerator

  def test_generates_locales
    run_generator
    assert_file "config/locales/flash.en.yml"
  end

  def test_generates_pundit_application_policy_if_missing
    policy_file = "app/policies/application_policy.rb"
    assert_no_file policy_file # sanity check

    run_generator
    assert_file policy_file

    File.write(File.join(destination_root, policy_file), "EXPECTED")

    run_generator
    assert_file policy_file, "EXPECTED"
  end
end
