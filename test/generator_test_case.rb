require "fileutils"
require "timeout"
require "test_helper"

class GeneratorTestCase < Rails::Generators::TestCase
  destination "#{__dir__}/tmp"

  def setup
    prepare_destination
  end

  private

  def prepare_routes
    FileUtils.mkdir_p("#{destination_root}/config")
    FileUtils.cp("#{__dir__}/dummy/config/routes.rb", "#{destination_root}/config/routes.rb")
  end

  def run_generator(*args)
    # Several generator tests test behavior on file conflict.  By
    # default, the failure mode for those tests (i.e. when the generator
    # handles the conflict incorrectly) is to hang indefinitely as the
    # generator waits for keyboard input.  So we prevent this with a
    # reasonable timeout.
    Timeout.timeout(15){ super }
  end

end
