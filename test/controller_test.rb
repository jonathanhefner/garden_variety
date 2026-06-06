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

class CustomYuuseju; end

class CustomUsagesController < ActionController::Base
  include GardenVariety::Controller
  self.model_class = CustomYuuseju
  garden_variety :index, :show
end


class ControllerTest < ActiveSupport::TestCase

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

  GARDEN_VARIETY_CONTROLLERS = CONTROLLER_MODELS.except(
    NoUsagesController,
    Namespaced::NoUsagesController,
  ).keys.freeze

  test "assumptions about Active Model naming" do
    assert_equal "namespaced_default_usage", Namespaced::DefaultUsage.model_name.singular
    assert_equal "Default usage", Namespaced::DefaultUsage.model_name.human
  end

  test "::garden_variety raises on invalid actions" do
    assert_raises(ArgumentError){ NoUsagesController.garden_variety :bad }
  end

  test "::model_class derives from controller path unless overridden" do
    CONTROLLER_MODELS.each do |controller_class, model_class|
      assert_equal model_class, controller_class.model_class
    end
  end

  test "::model_name is derived from ::model_class" do
    CONTROLLER_MODELS.each do |controller_class, model_class|
      assert_equal ActiveModel::Name.new(model_class), controller_class.model_name
    end
  end

  test "::model_name syncs with ::model_class=" do
    assert_equal DefaultUsage.model_name, DefaultUsagesController.model_name
    DefaultUsagesController.model_class = CustomYuuseju
    assert_equal CustomUsagesController.model_name, DefaultUsagesController.model_name
  ensure
    DefaultUsagesController.model_class = DefaultUsage # restore
  end

  test "#collection reads the plural-model instance variable" do
    GARDEN_VARIETY_CONTROLLERS.each do |controller_class|
      controller = controller_class.new
      collection_attr = controller_class.model_name.plural
      controller.instance_eval("@#{collection_attr} = :expected")
      assert_equal :expected, controller.send(:collection)
    end
  end

  test "#collection= writes the plural-model instance variable" do
    GARDEN_VARIETY_CONTROLLERS.each do |controller_class|
      controller = controller_class.new
      collection_attr = controller_class.model_name.plural
      assert_equal :expected, controller.send(:collection=, :expected)
      assert_equal :expected, controller.instance_eval("@#{collection_attr}")
    end
  end

  test "#model reads the singular-model instance variable" do
    GARDEN_VARIETY_CONTROLLERS.each do |controller_class|
      controller = controller_class.new
      model_attr = controller_class.model_name.singular
      controller.instance_eval("@#{model_attr} = :expected")
      assert_equal :expected, controller.send(:model)
    end
  end

  test "#model= writes the singular-model instance variable" do
    GARDEN_VARIETY_CONTROLLERS.each do |controller_class|
      controller = controller_class.new
      model_attr = controller_class.model_name.singular
      assert_equal :expected, controller.send(:model=, :expected)
      assert_equal :expected, controller.instance_eval("@#{model_attr}")
    end
  end

  test "::garden_variety includes all REST action modules by default" do
    assert_empty (ALL_ACTION_MODULES - DefaultUsagesController.included_modules)
  end

  test "controllers do not include action modules by default" do
    assert_equal ALL_ACTION_MODULES, (ALL_ACTION_MODULES - NoUsagesController.included_modules)
  end

  test "::garden_variety includes only requested action modules when specified" do
    action_modules = [GardenVariety::IndexAction, GardenVariety::ShowAction]
    assert_empty (action_modules - CustomUsagesController.included_modules)
  end

  test "#flash_options defaults model_name to the human model name" do
    CONTROLLER_MODELS.keys.each do |controller_class|
      model_name = controller_class.model_name.human
      actual = controller_class.new.send(:flash_options)
      assert_equal model_name, actual[:model_name]
    end
  end

  test "#flash_message prioritizes controller/action/status I18n keys" do
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

  test "#flash_message is scoped to controller_name, not model_name" do
    controller = CustomUsagesController.new
    controller.action_name = "test"
    status = "custom"
    # flash message is a controller concern, so key should be based on
    # controller name, NOT model name
    key = "#{controller.controller_name}.#{controller.action_name}.#{status}"
    store_translation(key, "expected")
    assert_equal "expected", controller.send(:flash_message, status)
  end

  test "#flash_message includes controller namespace in controller-specific I18n keys" do
    controller = Namespaced::DefaultUsagesController.new
    controller.action_name = "test"
    status = "namespaced"
    # full key should include namespace
    key = "#{controller.controller_path.tr("/", ".")}.#{controller.action_name}.#{status}"
    store_translation(key, "expected")
    assert_equal "expected", controller.send(:flash_message, status)
  end

  test "#flash_message preserves HTML safety for *_html I18n keys" do
    controller = DefaultUsagesController.new
    controller.action_name = "test"
    text = "<p>hello</p>"

    store_translation("literal_text", text)
    assert_not controller.send(:flash_message, "literal_text").html_safe?

    store_translation("raw_html", text)
    assert controller.send(:flash_message, "raw_html").html_safe?
  end

  private

  def store_translation(key, value)
    normalized = key.split(".").reverse.reduce(value){|acc, scope| { scope.to_sym => acc } }
    I18n.backend.store_translations(:en, flash: normalized)
  end

end
