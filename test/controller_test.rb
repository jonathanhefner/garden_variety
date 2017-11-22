require "test_helper"
require "garden_variety/controller"


class DefaultUsage; end

class DefaultUsagesController < ActionController::Base
  include GardenVariety::Controller
  garden_variety
end

class NoUsage; end

class NoUsagesController < ActionController::Base
  include GardenVariety::Controller
end

class CustomYuuseju; end

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

  def test_resource_class_base_behavior
    assert_equal NoUsage, NoUsagesController.new.send(:resource_class)
  end

  def test_resource_class_optimized_override
    assert_equal DefaultUsage, DefaultUsagesController.new.send(:resource_class)
  end

  def test_resource_class_with_custom_resource
    assert_equal CustomYuuseju, CustomUsagesController.new.send(:resource_class)
  end

  def test_resources_getter
    controller = DefaultUsagesController.new
    controller.instance_eval{ @default_usages = :expected }
    assert_equal :expected, controller.send(:resources)
  end

  def test_resources_setter
    controller = DefaultUsagesController.new
    assert_equal :expected, controller.send(:resources=, :expected)
    assert_equal :expected, controller.instance_eval{ @default_usages }
  end

  def test_resource_getter
    controller = DefaultUsagesController.new
    controller.instance_eval{ @default_usage = :expected }
    assert_equal :expected, controller.send(:resource)
  end

  def test_resource_setter
    controller = DefaultUsagesController.new
    assert_equal :expected, controller.send(:resource=, :expected)
    assert_equal :expected, controller.instance_eval{ @default_usage }
  end

  def test_resources_getter_with_custom_resource
    controller = CustomUsagesController.new
    controller.instance_eval{ @custom_yuusejus = :expected }
    assert_equal :expected, controller.send(:resources)
  end

  def test_resources_setter_with_custom_resource
    controller = CustomUsagesController.new
    assert_equal :expected, controller.send(:resources=, :expected)
    assert_equal :expected, controller.instance_eval{ @custom_yuusejus }
  end

  def test_resource_getter_with_custom_resource
    controller = CustomUsagesController.new
    controller.instance_eval{ @custom_yuuseju = :expected }
    assert_equal :expected, controller.send(:resource)
  end

  def test_resource_setter_with_custom_resource
    controller = CustomUsagesController.new
    assert_equal :expected, controller.send(:resource=, :expected)
    assert_equal :expected, controller.instance_eval{ @custom_yuuseju }
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
