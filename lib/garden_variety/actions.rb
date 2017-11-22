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
      self.resource = new_resource
      authorize(resource)
    end
  end

  module CreateAction
    # Garden variety controller +create+ action.
    # @return [void]
    def create
      self.resource = vest(new_resource)
      if resource.save
        redirect_to resource
      else
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
    # @return [void]
    def update
      self.resource = vest(find_resource)
      if resource.save
        redirect_to resource
      else
        render :edit
      end
    end
  end

  module DestroyAction
    # Garden variety controller +destroy+ action.
    # @return [void]
    def destroy
      self.resource = find_resource
      authorize(resource)
      resource.destroy
      redirect_to action: :index
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
