module GardenVariety

  REDIRECT_CODES = [301, 302, 303, 307, 308]

  module IndexAction
    # Garden variety controller +index+ action.
    # @return [void]
    def index
      authorize(self.class.model_class)
      self.resources = policy_scope(list_resources)
    end
  end

  module ShowAction
    # Garden variety controller +show+ action.
    # @return [void]
    def show
      self.resource = authorize(find_resource)
    end
  end

  module NewAction
    # Garden variety controller +new+ action.
    # @return [void]
    def new
      if params.key?(self.class.model_class.model_name.param_key)
        self.resource = vest(new_resource)
      else
        self.resource = authorize(new_resource)
      end
    end
  end

  module CreateAction
    # Garden variety controller +create+ action.
    # @overload create()
    # @overload create()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def create
      self.resource = (resource = vest(new_resource))
      if resource.save
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(resource)
        flash.discard(:success) if REDIRECT_CODES.exclude?(response.status)
      else
        flash.now[:error] = flash_message(:error)
        render :new
      end
    end
  end

  module EditAction
    # Garden variety controller +edit+ action.
    # @return [void]
    def edit
      self.resource = authorize(find_resource)
    end
  end

  module UpdateAction
    # Garden variety controller +update+ action.
    # @overload update()
    # @overload update()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def update
      self.resource = (resource = vest(find_resource))
      if resource.save
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(resource)
        flash.discard(:success) if REDIRECT_CODES.exclude?(response.status)
      else
        flash.now[:error] = flash_message(:error)
        render :edit
      end
    end
  end

  module DestroyAction
    # Garden variety controller +destroy+ action.
    # @overload destroy()
    # @overload destroy()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def destroy
      self.resource = (resource = authorize(find_resource))
      if resource.destroy
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(action: :index)
        flash.discard(:success) if REDIRECT_CODES.exclude?(response.status)
      else
        flash.now[:error] = flash_message(:error)
        render :show
      end
    end
  end

  # Map of controller action name to action module.  Used by the
  # {GardenVariety::Controller::ClassMethods#garden_variety} macro to
  # include desired controller actions.
  ACTION_MODULES = {
    index: IndexAction,
    show: ShowAction,
    new: NewAction,
    create: CreateAction,
    edit: EditAction,
    update: UpdateAction,
    destroy: DestroyAction,
  }

end
