require "fileutils"
require "timeout"
require "test_helper"
require "generators/garden/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Garden::Generators::InstallGenerator
  destination File.join(__dir__, "tmp")

  PUNDIT_POLICY_PATH = "app/policies/application_policy.rb"

  setup do
    prepare_destination

    Dir.chdir(__dir__) do
      FileUtils.copy_entry("dummy/bin", "tmp/bin")
      FileUtils.copy_entry("dummy/config", "tmp/config")
    end
  end

  def test_generates_installation_files
    run_generator
    assert_file "config/locales/flash.en.yml"
    assert_file PUNDIT_POLICY_PATH
  end

  def test_skips_pundit_files_if_already_installed
    policy_file = File.join(__dir__, "tmp", PUNDIT_POLICY_PATH)
    FileUtils.mkdir_p(File.dirname(policy_file))
    File.write(policy_file, "expected")

    # if missing skip option, generator will wait for keyboard input
    Timeout.timeout(15){ run_generator }
    assert_file policy_file, "expected"
  end
end
