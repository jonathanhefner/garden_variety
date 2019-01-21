require "fileutils"
require "timeout"
require "test_helper"
require "generators/garden/scaffold/scaffold_generator"

class ScaffoldGeneratorTest < Rails::Generators::TestCase
  tests Garden::Generators::ScaffoldGenerator
  destination File.join(__dir__, "tmp")

  LOCALES_FILE = "config/locales/garden_variety.en.yml"

  setup do
    prepare_destination

    Dir.chdir(__dir__) do
      FileUtils.copy_entry("dummy/bin", "tmp/bin")
      FileUtils.copy_entry("dummy/config", "tmp/config")
    end
  end

  def test_generates_scaffold_files
    File.delete(File.join(__dir__, "tmp", LOCALES_FILE))

    resource = "fruit"
    run_generator([resource, "name:string", "--primary-key-type=uuid"])

    assert_file LOCALES_FILE
    assert_file "config/routes.rb", /resources :#{resource.pluralize}/
    assert_migration "db/migrate/create_#{resource.pluralize}.rb" do |migration|
      assert_match "create_table :#{resource.pluralize}, id: :uuid", migration
      assert_match "t.string :name", migration
    end
    assert_file "app/models/#{resource}.rb"
    %w[index show new edit _form].each do |v|
      assert_file "app/views/#{resource.pluralize}/#{v}.html.erb"
    end
    assert_file "app/controllers/#{resource.pluralize}_controller.rb", /^\s+garden_variety$/
    assert_file "app/policies/#{resource}_policy.rb"
  end

  def test_skips_locales_if_conflict
    # ensure locales file contents will conflict with default locales file
    File.write(File.join(__dir__, "tmp", LOCALES_FILE), "EXPECTED")

    # generator will wait for keyboard input if the skip-on-conflict
    # option for copy locales is erroneously omitted
    Timeout.timeout(15){ run_generator(["vegetable"]) }

    assert_file LOCALES_FILE, /EXPECTED/
  end
end
