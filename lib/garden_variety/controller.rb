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

    # @!visibility public
    # Returns Hash of values for interpolation in flash messages via
    # I18n.  By default, returns +resource_name+ and
    # +resource_capitalized+ values appropriate to the controller.
    # Override this method to provide your own values.  Be aware that
    # certain option names, such as +default+ and +scope+, are reserved
    # by the I18n gem, and can not be used for interpolation.  See the
    # {https://www.rubydoc.info/gems/i18n I18n documentation} for more
    # information.
    #
    # @return [Hash]
    def flash_options
      { resource_name: resource_class.model_name.human.downcase,
        resource_capitalized: resource_class.model_name.human }
    end

    # @!visibility public
    # Returns a flash message appropriate to the controller, the current
    # action, and a given status.  The flash message is looked up via
    # I18n using a prioritized list of possible keys.  The key priority
    # is as follows:
    #
    # * +{controller_name}.{action_name}.{status}+
    # * +{controller_name}.{action_name}.{status}_html+
    # * +{action_name}.{status}+
    # * +{action_name}.{status}_html+
    # * +{status}+
    # * +{status}_html+
    #
    # If the controller is namespaced, the namespace will prefix
    # (dot-separated) the +{controller_name}+ portion of the key.
    #
    # I18n string interpolation can be used in flash messages, with
    # interpolated values provided by the {flash_options} method.
    #
    # @example Key priority
    #   ### config/locales/garden_variety.en.yml
    #   # en:
    #   #   success: "Success!"
    #   #   create:
    #   #     success: "%{resource_capitalized} created."
    #   #   delete:
    #   #     success: "%{resource_capitalized} deleted."
    #   #   posts:
    #   #     create:
    #   #       success: "Congratulations on your new post!"
    #
    #   # via PostsController#create
    #   flash_message(:success)  # == "Congratulations on your new post!"
    #
    #   # via PostsController#update
    #   flash_message(:success)  # == "Success!"
    #
    #   # via PostsController#delete
    #   flash_message(:success)  # == "Post deleted."
    #
    # @example Namespaced controller
    #   ### config/locales/garden_variety.en.yml
    #   # en:
    #   #   create:
    #   #     success: "Created new %{resource_name}."
    #   #   update:
    #   #     success: "Updated %{resource_name}."
    #   #   messages:
    #   #     drafts:
    #   #       update:
    #   #         success: "Draft saved."
    #
    #   # via Messages::DraftsController#create
    #   flash_message(:success)  # == "Created new draft."
    #
    #   # via Messages::DraftsController#update
    #   flash_message(:success)  # == "Draft saved."
    #
    # @param status [Symbol, String]
    # @return [String]
    def flash_message(status)
      controller_key = controller_path.tr("/", I18n.default_separator)
      keys = [
        :"#{controller_key}.#{action_name}.#{status}",
        :"#{controller_key}.#{action_name}.#{status}_html",
        :"#{action_name}.#{status}",
        :"#{action_name}.#{status}_html",
        :"#{status}",
        :"#{status}_html",
      ]
      helpers.translate(keys.shift, default: keys, **flash_options)
    end
  end
end
