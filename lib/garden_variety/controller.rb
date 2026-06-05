module GardenVariety
  module Controller
    extend ActiveSupport::Concern

    include Pundit::Authorization

    module ClassMethods
      # Macro to include garden variety implementations of specified
      # actions in the controller.  If no actions are specified, all
      # typical REST actions (index, show, new, create, edit, update,
      # destroy) are included.
      #
      # @see GardenVariety::IndexAction
      # @see GardenVariety::ShowAction
      # @see GardenVariety::NewAction
      # @see GardenVariety::CreateAction
      # @see GardenVariety::EditAction
      # @see GardenVariety::UpdateAction
      # @see GardenVariety::DestroyAction
      #
      # @example Default actions
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
      #   end
      #
      # @example Specific actions
      #   # This...
      #   class PostsController < ApplicationController
      #     garden_variety :index, :show
      #   end
      #
      #   # ...is equivalent to:
      #   class PostsController < ApplicationController
      #     include GardenVariety::IndexAction
      #     include GardenVariety::ShowAction
      #   end
      #
      # @param actions [Array<:index, :show, :new, :create, :edit, :update, :destroy>]
      # @return [void]
      # @raise [ArgumentError]
      #   if an invalid action is specified
      def garden_variety(*actions)
        actions.each do |action|
          unless ::GardenVariety::ACTION_MODULES.key?(action)
            raise ArgumentError, "Invalid action: #{action.inspect}"
          end
        end

        action_modules = actions.empty? ?
          ::GardenVariety::ACTION_MODULES.values :
          ::GardenVariety::ACTION_MODULES.values_at(*actions)

        action_modules.each{|m| include m }
      end

      # Returns the controller model class.  Defaults to a class
      # corresponding to the singular-form of the controller name.
      #
      # @example
      #   class PostsController < ApplicationController
      #   end
      #
      #   PostsController.model_class  # == Post (class)
      #
      # @return [Class]
      def model_class
        @model_class ||= controller_path.classify.constantize
      end

      # Sets the controller model class.
      #
      # @example
      #   class PublishedPostsController < ApplicationController
      #     self.model_class = Post
      #   end
      #
      # @param klass [Class]
      # @return [klass]
      def model_class=(klass)
        @model_name = nil
        @model_class = klass
      end

      # @!visibility private
      def model_name
        @model_name ||= model_class.try(:model_name) || ActiveModel::Name.new(model_class)
      end
    end

    private

    # @!visibility public
    # Returns the value of the singular-form instance variable dictated
    # by {ClassMethods#model_class ::model_class}.
    #
    # @example
    #   class PostsController
    #     def show
    #       # This...
    #       self.model
    #       # ...is equivalent to:
    #       @post
    #     end
    #   end
    #
    # @return [Object]
    def model
      instance_variable_get(:"@#{self.class.model_name.singular}")
    end

    # @!visibility public
    # Sets the value of the singular-form instance variable dictated
    # by {ClassMethods#model_class ::model_class}.
    #
    # @example
    #   class PostsController
    #     def show
    #       # This...
    #       self.model = value
    #       # ...is equivalent to:
    #       @post = value
    #     end
    #   end
    #
    # @param value [Object]
    # @return [value]
    def model=(value)
      instance_variable_set(:"@#{self.class.model_name.singular}", value)
    end

    # @!visibility public
    # Returns the value of the plural-form instance variable dictated
    # by {ClassMethods#model_class ::model_class}.
    #
    # @example
    #   class PostsController
    #     def index
    #       # This...
    #       self.collection
    #       # ...is equivalent to:
    #       @posts
    #     end
    #   end
    #
    # @return [Object]
    def collection
      instance_variable_get(:"@#{self.class.model_name.plural}")
    end

    # @!visibility public
    # Sets the value of the plural-form instance variable dictated
    # by {ClassMethods#model_class ::model_class}.
    #
    # @example
    #   class PostsController
    #     def index
    #       # This...
    #       self.collection = values
    #       # ...is equivalent to:
    #       @posts = values
    #     end
    #   end
    #
    # @param values [Object]
    # @return [values]
    def collection=(values)
      instance_variable_set(:"@#{self.class.model_name.plural}", values)
    end

    # @!visibility public
    # Returns an ActiveRecord::Relation representing instances of
    # {ClassMethods#model_class ::model_class}.  Designed for use in
    # generic +index+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def index
    #        @posts = find_collection.where(status: "published")
    #     end
    #   end
    #
    # @return [ActiveRecord::Relation]
    def find_collection
      self.class.model_class.all
    end

    # @!visibility public
    # Returns an instance of {ClassMethods#model_class ::model_class}
    # matching the +:id+ parameter of the current request (i.e.
    # +params[:id]+).  Designed for use in generic +show+, +edit+,
    # +update+, and +destroy+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def show
    #        @post = find_model
    #     end
    #   end
    #
    # @return [ActiveRecord::Base]
    # @raise [ActiveRecord::RecordNotFound]
    #   if a model instance with matching +:id+ cannot be found
    def find_model
      self.class.model_class.find(params[:id])
    end

    # @!visibility public
    # Returns a new instance of {ClassMethods#model_class ::model_class}.
    # Designed for use in generic +new+ and +create+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def new
    #        @post = new_model
    #     end
    #   end
    #
    # @return [ActiveRecord::Base]
    def new_model
      self.class.model_class.new
    end

    # @!visibility public
    # Populates the given +model+'s attributes with the current request
    # params permitted by the corresponding Pundit policy.  Returns the
    # given +model+ modified but not persisted.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def create
    #       @post = assign_attributes(authorize(Post.new))
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
    def assign_attributes(model)
      model.assign_attributes(permitted_attributes(model))
      model
    end

    # @!visibility public
    # Returns a Hash of values for interpolation in flash messages via
    # I18n.  By default, returns a +:model_name+ key / value pair with
    # the humanized name of {ClassMethods#model_class ::model_class}.
    # Override this method to provide your own values.  Be aware that
    # certain option names, such as +:default+ and +:scope+, are
    # reserved by the I18n gem, and can not be used for interpolation.
    # See the {https://www.rubydoc.info/gems/i18n I18n documentation}
    # for more information.
    #
    # @return [Hash{Symbol => #to_s}]
    def flash_options
      { model_name: self.class.model_name.human }
    end

    # @!visibility public
    # Returns a flash message appropriate to the controller, the current
    # action, and a given +status+.  The flash message is looked up via
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
    #   #     success: "%{model_name} created."
    #   #   delete:
    #   #     success: "%{model_name} deleted."
    #   #   posts:
    #   #     create:
    #   #       success: "Congratulations on your new post!"
    #   #   messages:
    #   #     drafts:
    #   #       update:
    #   #         success: "Draft saved."
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
    #   # via Messages::DraftsController#update
    #   flash_message(:success)  # == "Draft saved."
    #
    # @param status [Symbol, String]
    # @return [String]
    def flash_message(status)
      controller_key = controller_path.tr("/", I18n.default_separator)
      keys = [
        :"flash.#{controller_key}.#{action_name}.#{status}",
        :"flash.#{controller_key}.#{action_name}.#{status}_html",
        :"flash.#{action_name}.#{status}",
        :"flash.#{action_name}.#{status}_html",
        :"flash.#{status}",
        :"flash.#{status}_html",
      ]
      helpers.translate(keys.shift, default: keys, **flash_options)
    end
  end
end
