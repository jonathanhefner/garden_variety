Bundler.load.setup(:default, :development) # exclude :talent_scout group

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
require "rails/test_help"

Rails.backtrace_cleaner.add_filter{|line| line.sub("#{File.dirname(__dir__)}/", "") }

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "rake test"

ActiveSupport::TestCase.fixtures :all
