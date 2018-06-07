require "pundit"
require "garden_variety/actions"

module GardenVariety
  module Controller
    extend ActiveSupport::Concern

    include Pundit

    module ClassMethods
      # Macro to include garden variety implementations of specified
      # actions in the controller.  If no actions are specified, all
      # typical REST actions (index, show, new, create, edit, update,
      # destroy) are included.
      #
      # The optional +resources:+ parameter dictates which model class
      # and instance variables these actions use.  The parameter's
      # default value derives from the controller name.  The value must
      # be a resource name in plural form.
      #
      # The macro also defines the following accessor methods for use in
      # generic action and helper methods: +resources+, +resources=+,
      # +resource+, and +resource=+.  These accessors get and set the
      # instance variables dictated by the +resources:+ parameter.
      #
      # @example default usage
      #   # This...
      #   class PostsController < ApplicationController
      #     garden_variety
      #   end
      #
      #   # ...is equivalent to:
      #   class PostsController < ApplicationController
      #     include GardenVariety::IndexAction
      #     include GardenVariety::ShowAction
      #     include GardenVariety::NewAction
      #     include GardenVariety::CreateAction
      #     include GardenVariety::EditAction
      #     include GardenVariety::UpdateAction
      #     include GardenVariety::DestroyAction
      #
      #     private
      #
      #     def resource_class
      #       Post
      #     end
      #
      #     def resources
      #       @posts
      #     end
      #
      #     def resources=(models)
      #       @posts = models
      #     end
      #
      #     def resource
      #       @post
      #     end
      #
      #     def resource=(model)
      #       @post = model
      #     end
      #   end
      #
      # @example custom usage
      #   # This...
      #   class CountriesController < ApplicationController
      #     garden_variety :index, resources: :locations
      #   end
      #
      #   # ...is equivalent to:
      #   class CountriesController < ApplicationController
      #     include GardenVariety::IndexAction
      #
      #     private
      #
      #     def resource_class
      #       Location
      #     end
      #
      #     def resources
      #       @locations
      #     end
      #
      #     def resources=(models)
      #       @locations = models
      #     end
      #
      #     def resource
      #       @location
      #     end
      #
      #     def resource=(model)
      #       @location = model
      #     end
      #   end
      #
      # @param actions [Array<:index, :show, :new, :create, :edit, :update, :destroy>]
      # @param resources [Symbol, String]
      # @return [void]
      def garden_variety(*actions, resources: controller_path)
        resources_attr = resources.to_s.underscore.tr("/", "_")

        class_eval <<-CODE
          private

          def resource_class # optimized override
            #{resources.to_s.classify}
          end

          def resources
            @#{resources_attr}
          end

          def resources=(models)
            @#{resources_attr} = models
          end

          def resource
            @#{resources_attr.singularize}
          end

          def resource=(model)
            @#{resources_attr.singularize} = model
          end
        CODE

        action_modules = actions.empty? ?
          ::GardenVariety::ACTION_MODULES.values :
          ::GardenVariety::ACTION_MODULES.values_at(*actions)

        action_modules.each{|m| include m }
      end
    end


    private

    # @!visibility public
    # Returns the class of the resource corresponding to the controller
    # name.
    #
    # @example
    #   PostsController.new.resource_class  # == Post (class)
    #
    # @return [Class]
    def resource_class
      @resource_class ||= controller_path.classify.constantize
    end

    # @!visibility public
    # Returns an ActiveRecord::Relation representing resource instances
    # corresponding to the controller.  Designed for use in generic
    # +index+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def index
    #        @posts = list_resources.where(status: "published")
    #     end
    #   end
    #
    # @return [ActiveRecord::Relation]
    def list_resources
      resource_class.all
    end

    # @!visibility public
    # Returns a model instance corresponding to the controller and the
    # id parameter of the current request (i.e. +params[:id]+).
    # Designed for use in generic +show+, +edit+, +update+, and
    # +destroy+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def show
    #        @post = find_resource
    #     end
    #   end
    #
    # @return [ActiveRecord::Base]
    def find_resource
      resource_class.find(params[:id])
    end

    # @!visibility public
    # Returns a new model instance corresponding to the controller.
    # Designed for use in generic +new+ and +create+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def new
    #        @post = new_resource
    #     end
    #   end
    #
    # @return [ActiveRecord::Base]
    def new_resource
      resource_class.new
    end

    # @!visibility public
    # Authorizes the given model for the current action via the model
    # Pundit policy, and populates the model attributes with the current
    # request params permitted by the model policy.  Returns the given
    # model modified but not persisted.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def create
    #       @post = vest(Post.new)
    #       if @post.save
    #         redirect_to @post
    #       else
    #         render :new
    #       end
    #     end
    #   end
    #
    # @param model [ActiveRecord::Base]
    # @return [ActiveRecord::Base]
    def vest(model)
      authorize(model)
      model.assign_attributes(permitted_attributes(model))
      model
    end
  end
end
