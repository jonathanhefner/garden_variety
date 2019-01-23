require "test_helper"
require "garden_variety"


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
  self.resource_class = CustomYuuseju
  garden_variety :index, :show
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
    assert_equal "namespaced_default_usage", Namespaced::DefaultUsage.model_name.singular
    assert_equal "Default usage", Namespaced::DefaultUsage.model_name.human
  end

  def test_resource_class
    CONTROLLER_MODELS.each do |controller_class, model_class|
      assert_equal model_class, controller_class.resource_class
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

  def test_flash_options
    CONTROLLER_MODELS.each do |controller_class, model_class|
      resource_name = model_class.model_name.human.downcase
      actual = controller_class.new.send(:flash_options)
      assert_equal resource_name, actual[:resource_name]
      assert_equal resource_name.capitalize, actual[:resource_capitalized]
    end
  end

  def test_flash_message_key_priority
    controller = DefaultUsagesController.new
    controller.action_name = "test"
    status = "priority"

    flash_options = { extra: "info" }
    controller.send(:define_singleton_method, :flash_options, ->{ flash_options })

    scopes = [controller.controller_name, controller.action_name, status]
    prioritized_keys = scopes.length.downto(1).map{|n| scopes.last(n).join(".") }.
      flat_map{|key| [key, "#{key}_html"] }

    translations = prioritized_keys.reduce({}){|h, key| h.merge(key => "#{key} %{extra}") }
    translations.each{|key, value| store_translation(key, value) }

    prioritized_keys.each do |key|
      assert_equal(translations[key] % flash_options, controller.send(:flash_message, status))
      store_translation(key, nil)
    end
  end

  def test_flash_message_with_custom_resource
    controller = CustomUsagesController.new
    controller.action_name = "test"
    status = "custom"
    # flash message is a controller concern, so key should be based on
    # controller name, NOT model name
    key = "#{controller.controller_name}.#{controller.action_name}.#{status}"
    store_translation(key, "expected")
    assert_equal "expected", controller.send(:flash_message, status)
  end

  def test_flash_message_with_namespace
    controller = Namespaced::DefaultUsagesController.new
    controller.action_name = "test"
    status = "namespaced"
    # full key should include namespace
    key = "#{controller.controller_path.tr("/", ".")}.#{controller.action_name}.#{status}"
    store_translation(key, "expected")
    assert_equal "expected", controller.send(:flash_message, status)
  end

  def test_flash_message_html_escaping
    controller = DefaultUsagesController.new
    controller.action_name = "test"
    text = "<p>hello</p>"

    store_translation("literal_text", text)
    refute controller.send(:flash_message, "literal_text").html_safe?

    store_translation("raw_html", text)
    assert controller.send(:flash_message, "raw_html").html_safe?
  end

  private

  def store_translation(key, value)
    normalized = key.split(".").reverse.reduce(value){|acc, scope| { scope.to_sym => acc } }
    I18n.backend.store_translations(:en, normalized)
  end

end
