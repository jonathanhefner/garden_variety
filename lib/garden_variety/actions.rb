module GardenVariety

  module IndexAction
    # Garden variety controller +index+ action.
    # @return [void]
    def index
      authorize(resource_class)
      self.resources = policy_scope(list_resources)
    end
  end

  module ShowAction
    # Garden variety controller +show+ action.
    # @return [void]
    def show
      self.resource = find_resource
      authorize(resource)
    end
  end

  module NewAction
    # Garden variety controller +new+ action.
    # @return [void]
    def new
      if params.key?(resource_class.model_name.param_key)
        self.resource = vest(new_resource)
      else
        self.resource = new_resource
        authorize(resource)
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
      self.resource = vest(new_resource)
      if resource.save
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(resource)
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
      self.resource = find_resource
      authorize(resource)
    end
  end

  module UpdateAction
    # Garden variety controller +update+ action.
    # @overload update()
    # @overload update()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def update
      self.resource = vest(find_resource)
      if resource.save
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(resource)
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
      self.resource = find_resource
      authorize(resource)
      if resource.destroy
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(action: :index)
      else
        flash[:error] = flash_message(:error)
        redirect_back(fallback_location: { action: :show })
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
