require "pundit"
require "garden_variety/version"
require "garden_variety/actions"
require "garden_variety/controller"
require "garden_variety/current_user_stub"

begin
  require "talent_scout"
rescue LoadError
  # do nothing
else
  require "garden_variety/talent_scout"
end

require "garden_variety/railtie"
