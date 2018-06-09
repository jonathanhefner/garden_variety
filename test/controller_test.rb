require "test_helper"
require "garden_variety/controller"


class DefaultUsage < ActiveRecord::Base; end

class DefaultUsagesController < ActionController::Base
  include GardenVariety::Controller
  garden_variety
end

class NoUsage < ActiveRecord::Base; end

class NoUsagesController < ActionController::Base
  include GardenVariety::Controller
end

module Namespaced
  class DefaultUsage < ActiveRecord::Base; end
  class NoUsage < ActiveRecord::Base; end
end

class Namespaced::DefaultUsagesController < ActionController::Base
  include GardenVariety::Controller
  garden_variety
end

class Namespaced::NoUsagesController < ActionController::Base
  include GardenVariety::Controller
end

class CustomYuuseju < ActiveRecord::Base; end

class CustomUsagesController < ActionController::Base
  include GardenVariety::Controller
  garden_variety :index, :show, resources: :custom_yuusejus
end


class ControllerTest < Minitest::Test

  ALL_ACTION_MODULES = [
    GardenVariety::IndexAction, GardenVariety::ShowAction,
    GardenVariety::NewAction, GardenVariety::CreateAction,
    GardenVariety::EditAction, GardenVariety::UpdateAction,
    GardenVariety::DestroyAction
  ].freeze

  CONTROLLER_MODELS = {
    DefaultUsagesController => DefaultUsage,
    NoUsagesController => NoUsage,
    Namespaced::DefaultUsagesController => Namespaced::DefaultUsage,
    Namespaced::NoUsagesController => Namespaced::NoUsage,
    CustomUsagesController => CustomYuuseju,
  }.freeze

  GARDEN_VARIETY_CONTROLLER_MODELS = CONTROLLER_MODELS.except(
    NoUsagesController,
    Namespaced::NoUsagesController,
  ).freeze

  def test_assumptions
    assert_match %r"^namespaced_", Namespaced::DefaultUsage.model_name.singular
  end

  def test_resource_class
    CONTROLLER_MODELS.each do |controller_class, model_class|
      assert_equal model_class, controller_class.new.send(:resource_class)
    end
  end

  def test_resources_getter
    GARDEN_VARIETY_CONTROLLER_MODELS.each do |controller_class, model_class|
      controller = controller_class.new
      resources_attr = model_class.model_name.plural
      controller.instance_eval("@#{resources_attr} = :expected")
      assert_equal :expected, controller.send(:resources)
    end
  end

  def test_resources_setter
    GARDEN_VARIETY_CONTROLLER_MODELS.each do |controller_class, model_class|
      controller = controller_class.new
      resources_attr = model_class.model_name.plural
      assert_equal :expected, controller.send(:resources=, :expected)
      assert_equal :expected, controller.instance_eval("@#{resources_attr}")
    end
  end

  def test_resource_getter
    GARDEN_VARIETY_CONTROLLER_MODELS.each do |controller_class, model_class|
      controller = controller_class.new
      resource_attr = model_class.model_name.singular
      controller.instance_eval("@#{resource_attr} = :expected")
      assert_equal :expected, controller.send(:resource)
    end
  end

  def test_resource_setter
    GARDEN_VARIETY_CONTROLLER_MODELS.each do |controller_class, model_class|
      controller = controller_class.new
      resource_attr = model_class.model_name.singular
      assert_equal :expected, controller.send(:resource=, :expected)
      assert_equal :expected, controller.instance_eval("@#{resource_attr}")
    end
  end

  def test_include_default_actions
    assert_empty (ALL_ACTION_MODULES - DefaultUsagesController.included_modules)
  end

  def test_include_no_actions
    assert_equal ALL_ACTION_MODULES, (ALL_ACTION_MODULES - NoUsagesController.included_modules)
  end

  def test_include_custom_actions
    action_modules = [GardenVariety::IndexAction, GardenVariety::ShowAction]
    assert_empty (action_modules - CustomUsagesController.included_modules)
  end

end
