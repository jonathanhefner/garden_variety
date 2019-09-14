require "fileutils"
require "timeout"
require "test_helper"

# NOTE: Performance gains from parallelization are limited to ~2 tests
# per GeneratorTestCase (possibly more on an SSD).  More tests than that
# lose performance due to disk thrashing.
class GeneratorTestCase < Rails::Generators::TestCase
  include ActiveSupport::Testing::Isolation
  # HACK skip fixtures (which aren't necessary for generator tests),
  # else tests parallelized with Rails 5.1 cause SQLite3::BusyException
  self.fixture_table_names = []

  def setup
    self.class.destination File.join(__dir__, "tmp", Process.pid.to_s)
    prepare_destination

    Dir.chdir(__dir__) do
      FileUtils.copy_entry("dummy/bin", "tmp/#{Process.pid}/bin")
      FileUtils.copy_entry("dummy/config", "tmp/#{Process.pid}/config")
    end
  end

  def teardown
    rm_rf(destination_root)
  end

  private

  def run_generator(*args)
    # Several generator tests test behavior on file conflict.  By
    # default, the failure mode for those tests (i.e. when the generator
    # handles the conflict incorrectly) is to hang indefinitely as the
    # generator waits for keyboard input.  So we prevent this with a
    # reasonable timeout.
    Timeout.timeout(15){ super }
  end

end
