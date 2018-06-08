# garden_variety

Delightfully boring Rails controllers.  One of the superb advantages of
Ruby on Rails is convention over configuration.  Opinionated default
behavior can decrease development time, and increase application
robustness (less custom code == less that can go wrong).  In service of
this principle, *garden_variety* provides reasonable default controller
actions, with care to allow easy override.

*garden_variety* also uses the excellent
[Pundit](https://rubygems.org/gems/pundit) gem to isolate authorization
concerns.  If you're unfamiliar with Pundit, see its documentation for
an explanation of policy objects and how they help controller actions
stay DRY and boring.

As an example, this controller using `garden_variety`...

```ruby
class PostsController < ApplicationController
  garden_variety
end
```

...is equivalent to the following conventional implementation:

```ruby
class PostsController < ApplicationController

  def index
    authorize(resource_class)
    self.resources = policy_scope(list_resources)
  end

  def show
    self.resource = find_resource
    authorize(resource)
  end

  def new
    if params.key?(resource_class.model_name.param_key)
      self.resource = vest(new_resource)
    else
      self.resource = new_resource
      authorize(resource)
    end
  end

  def create
    self.resource = vest(new_resource)
    if resource.save
      redirect_to resource
    else
      render :new
    end
  end

  def edit
    self.resource = find_resource
    authorize(resource)
  end

  def update
    self.resource = vest(find_resource)
    if resource.save
      redirect_to resource
    else
      render :edit
    end
  end

  def destroy
    self.resource = find_resource
    authorize(resource)
    if resource.destroy
      redirect_to action: :index
    else
      redirect_back(fallback_location: { action: :show })
    end
  end

  private

  def resource_class
    Post
  end

  def resources
    @posts
  end

  def resources=(models)
    @posts = models
  end

  def resource
    @post
  end

  def resource=(model)
    @post = model
  end

  def list_resources
    resource_class.all
  end

  def find_resource
    resource_class.find(params[:id])
  end

  def new_resource
    resource_class.new
  end

  def vest(model)
    authorize(model)
    model.assign_attributes(permitted_attributes(model))
    model
  end

end
```

The implementations of the `resource_class` and `resource` / `resources`
accessor methods are generated based on the controller name.  They can
be altered with an optional argument to the `garden_variety` macro.  The
rest of the methods can be overridden as normal, a la carte.  For a
detailed description of method behavior, see the
[full documentation](http://www.rubydoc.info/gems/garden_variety/).
(Note that the `authorize`, `policy_scope`, and `permitted_attributes`
methods are provided by Pundit.)


## Scaffold generator

*garden_variety* includes a scaffold generator similar to the Rails
scaffold generator:

```
$ rails generate garden:scaffold post title:string body:text published:boolean
    generate  resource
      invoke  active_record
      create    db/migrate/19991231235959_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
      invoke    assets
      invoke      coffee
      create        app/assets/javascripts/posts.coffee
      invoke      scss
      create        app/assets/stylesheets/posts.scss
      invoke  resource_route
       route    resources :posts
    generate  erb:scaffold
       exist  app/views/posts
      create  app/views/posts/index.html.erb
      create  app/views/posts/edit.html.erb
      create  app/views/posts/show.html.erb
      create  app/views/posts/new.html.erb
      create  app/views/posts/_form.html.erb
      insert  app/controllers/posts_controller.rb
    generate  pundit:policy
      create  app/policies/post_policy.rb
      invoke  test_unit
      create    test/policies/post_policy_test.rb
```

The generated controller will contain only a call to the
`garden_variety` macro.  Also, as you can see from the command output,
the *garden_variety* scaffold generator differs from the Rails scaffold
generator in a few small ways:

* No scaffold CSS (i.e. no "app/assets/stylesheets/scaffolds.scss").
* No jbuilder templates.  Only HTML templates are generated.
* `rails generate pundit:policy` is invoked for the specified model.


## Beyond garden variety behavior

*garden_variety* is designed to reduce the amount of custom code
written, including in situations where custom code is unavoidable.


### Integrating with search

It is possible to integrate searching functionality by overriding the
`index` action.  However, it can be simpler to override the
`list_resources` method instead:

```ruby
class PostsController < ApplicationController
  garden_variety

  def list_resources
    params[:author] ? super.where(author: params[:author]) : super
  end
end
```


### Integrating with pagination

Your favorite pagination gem (*may I suggest
[foliate](https://rubygems.org/gems/foliate)?*) can also be integrated
by overriding the `list_resources` action:

```ruby
class PostsController < ApplicationController
  garden_variety

  def list_resources
    paginate(super)
  end
end
```


### Integrating with authentication

The details of integrating authentication will depend on your chosen
authentication library.  [Devise](https://rubygems.org/gems/devise) is
the most popular, but [Clearance](https://rubygems.org/gems/clearance)
is also a strong choice.  Whatever library you choose, it is likely to
include a "before filter" which you must invoke in your controller to
enforce authentication.  Something similar to the following:

```ruby
class PostsController < ApplicationController
  garden_variety
  before_action :authenticate_user!
end
```

Your authentication library is also likely to provide a `current_user`
method, which will return an appropriate value when the user is
authenticated.  Pundit automatically uses this method to enforce
authorization policies.  See your authentication library's documentation
to verify that it provides this method, or see Pundit's documentation
for details on using a different method to identify the current user.

*garden_variety* also provides a stub implementation of `current_user`,
so that if no authentication library is chosen, `current_user` will be
defined to always return nil.

**Note about Clearance:** Clearance versions previous to 2.0 define a
deprecated `authorize` method which conflicts with Pundit.  To avoid
this conflict, add the following line to your Clearance initializer:

```ruby
::Clearance::Authorization.send(:remove_method, :authorize)
```


### Integrating with Form Objects

The Form Object pattern is used to mitigate the complexity of handling
forms which need special processing logic, such as context-dependent
validation, or forms which involve more than one model.  A detailed
explanation of the pattern is beyond the scope of this document, but
consider the following minimal example:

```ruby
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :email, :password, :accept_terms_of_service

  validates :accept_terms_of_service, presence: true, acceptance: true

  def save
    @user = User.new(email: email, password: password)
    if [valid?, @user.valid?].all?
      @user.save
    else
      @user.errors.each{|attr, message| errors.add(attr, message) }
      false
    end
  end
end


class RegistrationFormsController < ApplicationController
  garden_variety :new

  def create
    self.resource = vest(new_resource)
    if resource.save
      redirect_to root_path # redirect to front page instead of show
    else
      render :new
    end
  end
end
```

Only the `new` controller action is generated by the `garden_variety`
macro.  The `create` action is implemented directly in order to redirect
to `root_path` rather than the resource itself, as would be
conventional.  The *garden_variety* helper methods all work as expected
because `RegistrationForm` responds to `assign_attributes` and `save`,
and has a default (nullary) constructor.

This pattern of overriding a controller action merely to respond
differently upon success is common enough that *garden_variety* provides
a concise syntax for it:

```ruby
class RegistrationFormsController < ApplicationController
  garden_variety :new, :create

  def create
    super{ redirect_to root_path }
  end
end
```

In the above example, the `garden_variety` macro generates a
conventional `create` action, which is then invoked via `super` in the
`create` override.  Here, when a block is passed to `super`, it is
treated as an on-success callback which replaces the default redirect.
This callback behavior is also available for the `update` and `destroy`
actions.


### Non-REST actions

You may also define any non-REST controller actions you wish (i.e.
actions other than: `index`, `show`, `new`, `create`, `edit`, `update`,
and `destroy`).  The helper methods *garden_variety* provides may be
useful when doing so.

However, before implementing a non-REST controller action, consider if
the behavior might be better implemented as a REST action in a new
controller.  For example, instead of the following `published` action...

```ruby
class PostsController < ApplicationController
  garden_variety

  def published
    @posts = Post.where(published: true)
    render :index
  end
end
```

...consider a new controller:

```ruby
class PublishedPostsController < ApplicationController
  garden_variety :index, resources: :posts

  def list_resources
    super.where(published: true)
  end
end
```

Note the `resources:` argument to the `garden_variety` macro.  The
resource class for `PublishedPostsController` will be overridden as
`Post` instead of derived as `PublishedPost`.  Likewise, the `@posts`
instance variable will be used instead of `@published_posts`.

This example may be somewhat contrived, but there is an excellent talk
from RailsConf which delves deeper into the principle:
[In Relentless Pursuit of REST](https://www.youtube.com/watch?v=HctYHe-YjnE)
([slides](https://speakerdeck.com/derekprior/in-relentless-pursuit-of-rest)).


## Installation

Add this line to your application's Gemfile:

```ruby
gem "garden_variety"
```

Then execute:

```bash
$ bundle install
```

And finally, if you haven't already used and installed Pundit, run the
Pundit installation generator:

```bash
$ rails generate pundit:install
```


## Contributing

Run `rake test` to run the tests.


## License

[MIT License](https://opensource.org/licenses/MIT)
