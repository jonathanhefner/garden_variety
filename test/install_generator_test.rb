require "fileutils"
require "test_helper"
require_relative "generator_test_case"
require "generators/garden/install/install_generator"

class InstallGeneratorTest < GeneratorTestCase
  tests Garden::Generators::InstallGenerator

  LOCALES_FILE = "config/locales/flash.en.yml"
  PUNDIT_FILE = "app/policies/application_policy.rb"

  def test_generates_installation_files
    run_generator
    assert_file LOCALES_FILE
    assert_file PUNDIT_FILE
  end

  def test_skips_pundit_files_if_already_installed
    FileUtils.mkdir_p(File.dirname(File.join(destination_root, PUNDIT_FILE)))
    File.write(File.join(destination_root, PUNDIT_FILE), "EXPECTED")

    run_generator
    assert_file PUNDIT_FILE, "EXPECTED"
  end
end
