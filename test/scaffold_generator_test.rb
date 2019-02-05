require "test_helper"
require_relative "generator_test_case"
require "generators/garden/scaffold/scaffold_generator"

class ScaffoldGeneratorTest < GeneratorTestCase
  tests Garden::Generators::ScaffoldGenerator

  LOCALES_FILE = "config/locales/flash.en.yml"

  def test_generates_scaffold_files_and_missing_locales
    File.delete(File.join(destination_root, LOCALES_FILE))

    generate_scaffold("fruit")
    assert_file LOCALES_FILE
    assert_scaffold("fruit")
  end

  def test_generates_namespaced_scaffold_files_and_skips_conflicting_locales
    # ensure locales file contents will conflict with default locales file
    File.write(File.join(destination_root, LOCALES_FILE), "EXPECTED")

    generate_scaffold("spaced/vegetable")
    assert_file LOCALES_FILE, "EXPECTED"
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
