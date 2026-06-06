return if Bundler.load.dependencies.none?{|dep| dep.name == "talent_scout" }
require "test_helper"

class TalentScoutTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    # sanity check
    assert_not defined?(::TalentScout)
    assert_not defined?(::GardenVariety::TalentScout)
    # enable talent_scout gem group
    Bundler.load.setup(:default, :talent_scout)
    # reload garden_variety, which will now load talent_scout plus integration
    load File.join(__dir__, "../lib/garden_variety.rb")
    # sanity check
    assert defined?(::TalentScout)
    assert defined?(::GardenVariety::TalentScout)
    # manually run talent_scout initializers because the initialization phase is past
    TalentScout::Railtie.initializers.each(&:run)
    # manually include talent_scout integration modules
    # NOTE: Ideally this would be done by re-running the garden_variety
    # initializers, which would re-include GardenVariety::Controller
    # into ActionController::Base, thus inserting the newly loaded
    # integration modules into ActionController::Base's ancestor chain.
    # But, as of Rails 5.2, ActiveSupport::Concern incorrectly prevents
    # re-including a module.
    GardenVariety::Controller.ancestors.each{|mod| ActionController::Base.include(mod) }
    # now that talent_scout is loaded, define search class for tests
    self.class.const_set("MyModelSearch", Class.new(TalentScout::ModelSearch))
  end

  test "::model_search_class derives from ::model_class" do
    assert_equal MyModelSearch, MyModelsController.model_search_class
    assert_equal MyModelSearch, MyModelsController.model_search_class?
  end

  test "::model_search_class follows overridden ::model_class" do
    assert_equal MyModelSearch, MyOtherModelsController.model_search_class
    assert_equal MyModelSearch, MyOtherModelsController.model_search_class?
  end

  test "::model_search_class raises when the model search class does not exist" do
    assert_raises(NameError){ UnsearchablesController.model_search_class }
    assert_not UnsearchablesController.model_search_class?
  end

  test "#find_collection uses search results when a search class exists" do
    controller = MyModelsController.new
    controller.params = ActionController::Parameters.new
    assert_equal MyModel.all, controller.send(:find_collection)
    assert_instance_of MyModelSearch, controller.instance_eval{ @search }
  end

  test "#find_collection falls back to the model finder method when the model search class does not exist" do
    controller = UnsearchablesController.new
    assert_equal Unsearchable.all, controller.send(:find_collection)
    assert_nil controller.instance_eval{ defined?(@search) }
  end

  private

  class MyModel
    cattr_accessor(:all){ self.new }
  end

  class MyModelsController < ActionController::Base
  end

  class MyOtherModelsController < ActionController::Base
    self.model_class = MyModel
  end

  class Unsearchable
    cattr_accessor(:all){ self.new }
  end

  class UnsearchablesController < ActionController::Base
  end

end
