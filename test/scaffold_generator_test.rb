require "fileutils"
require "timeout"
require "test_helper"
require "generators/garden/scaffold/scaffold_generator"

class ScaffoldGeneratorTest < Rails::Generators::TestCase
  tests Garden::Generators::ScaffoldGenerator
  destination File.join(__dir__, "tmp")

  setup do
    prepare_destination

    Dir.chdir(__dir__) do
      FileUtils.copy_entry("dummy/bin", "tmp/bin")
      FileUtils.copy_entry("dummy/config", "tmp/config")
    end
  end

  teardown :prepare_destination # prevent generated *_test.rb files from confusing `rake test`

  LOCALES_FILE = "config/locales/flash.en.yml"

  def test_generates_scaffold_files_and_missing_locales
    File.delete(File.join(__dir__, "tmp", LOCALES_FILE))
    generate_scaffold("fruit")
    assert_file LOCALES_FILE
    assert_scaffold("fruit")
  end

  def test_generates_namespaced_scaffold_files_and_skips_conflicting_locales
    # ensure locales file contents will conflict with default locales file
    File.write(File.join(__dir__, "tmp", LOCALES_FILE), "EXPECTED")

    # generator will wait for keyboard input if the skip-on-conflict
    # option for copy locales is erroneously omitted
    Timeout.timeout(15){ generate_scaffold("spaced/vegetable") }

    assert_file LOCALES_FILE, /EXPECTED/
    assert_scaffold("spaced/vegetable")
  end

  private

  def generate_scaffold(resource)
    run_generator([resource, "name:string", "--primary-key-type=uuid"])
  end

  def assert_scaffold(resource)
    names = resource.split("/")
    assert_file "config/routes.rb" do |routes|
      names[0...-1].each{|name| assert_match "namespace :#{name}", routes }
      assert_match "resources :#{names[-1].pluralize}", routes
    end

    table_name = resource.pluralize.tr("/", "_")
    assert_migration "db/migrate/create_#{table_name}.rb" do |migration|
      assert_match "create_table :#{table_name}, id: :uuid", migration
      assert_match "t.string :name", migration
    end

    assert_file "app/models/#{resource}.rb"

    %w[index show new edit _form].each do |view|
      assert_file "app/views/#{resource.pluralize}/#{view}.html.erb"
    end

    assert_file "app/controllers/#{resource.pluralize}_controller.rb", /^\s+garden_variety$/

    assert_file "app/policies/#{resource}_policy.rb"
  end

end
