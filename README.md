# garden_variety

Delightfully boring Rails controllers.  One of the superb advantages of
Ruby on Rails is convention over configuration.  Opinionated default
behavior can decrease development time and increase application
robustness (less custom code == less that can go wrong).  In service of
this principle, *garden_variety* provides reasonable default controller
actions, with care to allow easy override.

*garden_variety* also relies on the [Pundit](https://rubygems.org/gems/pundit)
gem to isolate authorization concerns.  If you're unfamiliar with
Pundit, see its documentation for an explanation of policy objects and
how they help controller actions stay DRY and boring.

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
    authorize(self.class.model_class)
    self.collection = policy_scope(find_collection)
  end

  def show
    self.model = authorize(find_model)
  end

  def new
    self.model = authorize(new_model)
    if params.key?(self.class.model_class.model_name.param_key)
      assign_attributes(model)
    end
  end

  def create
    self.model = assign_attributes(authorize(new_model))
    if model.save
      flash[:success] = flash_message(:success)
      redirect_to model
    else
      flash.now[:error] = flash_message(:error)
      render :new
    end
  end

  def edit
    self.model = authorize(find_model)
  end

  def update
    self.model = assign_attributes(authorize(find_model))
    if model.save
      flash[:success] = flash_message(:success)
      redirect_to model
    else
      flash.now[:error] = flash_message(:error)
      render :edit
    end
  end

  def destroy
    self.model = authorize(find_model)
    if model.destroy
      flash[:success] = flash_message(:success)
      redirect_to action: :index
    else
      flash.now[:error] = flash_message(:error)
      render :show
    end
  end

  private

  def self.model_class
    Post
  end

  def collection
    @posts
  end

  def collection=(models)
    @posts = models
  end

  def model
    @post
  end

  def model=(model)
    @post = model
  end

  def find_collection
    self.class.model_class.all
  end

  def find_model
    self.class.model_class.find(params[:id])
  end

  def new_model
    self.class.model_class.new
  end

  def assign_attributes(model)
    model.assign_attributes(permitted_attributes(model))
    model
  end

  def flash_options
    { model_name: "Post" }
  end

  def flash_message(status)
    keys = [
      :"flash.posts.#{action_name}.#{status}",
      :"flash.posts.#{action_name}.#{status}_html",
      :"flash.#{action_name}.#{status}",
      :"flash.#{action_name}.#{status}_html",
      :"flash.#{status}",
      :"flash.#{status}_html",
    ]
    helpers.translate(keys.first, { default: keys.drop(1), **flash_options })
  end

end
```

The `::model_class` method returns a class corresponding to the
controller name, by default.  That value can be overridden using the
matching `::model_class=` setter.  The `model` / `collection` accessor
method definitions are dictated by `::model_class`.  The rest of the
methods can be overridden as normal, a la carte.  For a detailed
description of method behavior, see the [API documentation](
https://www.rubydoc.info/gems/garden_variety/).  (Note that the
`authorize`, `policy_scope`, and `permitted_attributes` methods are
provided by Pundit.)


## Scaffold generator

*garden_variety* includes a `garden:scaffold` generator similar to the
Rails `scaffold` generator:

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

Additionally, if you are using the [talent_scout] gem, the scaffold
generator will invoke `rails generate talent_scout:search` for the
specified model.  This behavior can be disabled with the
`--skip-talent-scout` option.  For more information about integrating
with *talent_scout*, see the [Searching with talent_scout](
#searching-with-talent_scout) section below.

[talent_scout]: https://rubygems.org/gems/talent_scout


## Flash messages

Flash messages are defined using I18n.  The *garden_variety* installer
(`rails generate garden:install`) will create a
"config/locales/flash.en.yml" file containing default "success" and
"error" messages.  You can edit this file to customize those messages,
or add your own translation files to support other languages.

As seen in the `PostsController#flash_message` method in the example
above, a prioritized list of keys are tried when retrieving a flash
message.  Keys specific to the controller are tried first, followed by
keys specific to the action, and then finally generic status keys.  For
each level of specificity, `*_html` key variants are supported, which
allow raw HTML to be included in flash messages and not be escaped when
rendered.  (See the [Safe HTML Translations] section of the Rails
Internationalization guide for more information.)

Interpolation in flash messages is also supported (as described by
[Passing Variables to Translations]), with interpolation values provided
by the `flash_options` method.  By default, `flash_options` provides a
`model_name` value, but you can override it to provide your own values.

[Safe HTML Translations]: https://guides.rubyonrails.org/i18n.html#using-safe-html-translations
[Passing Variables to Translations]: https://guides.rubyonrails.org/i18n.html#passing-variables-to-translations


## Beyond garden variety behavior

*garden_variety* is designed to reduce the amount of custom code
written, including in situations where custom code is unavoidable.


### Eliminating N+1 queries

With proper Russian doll caching, [N+1 queries can be a feature](
https://youtu.be/ktZLpjCanvg?t=4m27s).  But, if you need to eliminate
an N+1 query by using eager loading, you can override the
`find_collection` method:

```ruby
class PostsController < ApplicationController
  garden_variety

  def find_collection
    super.includes(:author)
  end
end
```


### Pagination

You can integrate your your favorite pagination gem (*may I suggest
[moar](https://rubygems.org/gems/moar)?*) by overriding the
`find_collection` method:

```ruby
class PostsController < ApplicationController
  garden_variety

  def find_collection
    moar(super.order(:created_at))
  end
end
```


### Searching

You can provide search functionality by overriding the `find_collection`
method:

```ruby
class PostsController < ApplicationController
  garden_variety

  def find_collection
    params[:title] ? super.where("title LIKE ?", "%#{params[:title]}%") : super
  end
end
```

#### Searching with talent_scout

If you are using the [talent_scout] gem, the default implementation of
`find_collection` will automatically instantiate your model search class
-- no custom code required.  For example, if a `PostSearch` class is
defined, `PostsController#find_collection` will be equivalent to:

```ruby
def find_collection
  @search = PostSearch.new(params[:q])
  @search.results
end
```

Notice, as a side effect, the `@search` instance variable is set for
later use in the view.

The model search class will be chosen based on the controller's
`::model_class`.  For example:

```ruby
class MyPostsController < ApplicationController
  garden_variety

  self.model_class = Post # find_collection will use PostSearch instead of MyPostSearch
end
```

If a corresponding model search class is not defined, `find_collection`
will fall back to its original non-search behavior.

Alternatively, you can override the model search class directly:

```ruby
class MyPostsController < ApplicationController
  garden_variety

  self.model_class = Post
  self.model_search_class = MyPostSearch # find_collection will use MyPostSearch
end
```


### Server-generated JavaScript Responses (SJR)

SJR controller actions are generally the same as conventional controller
actions, with one difference: non-GET SJR actions render instead of
redirect on success.  *garden_variety* provides a concise syntax for
overriding only the on-success behavior of non-GET actions:

```ruby
class PostsController < ApplicationController
  garden_variety

  def create
    super{ render plain: "text" } # renders text on success instead of redirect
  end
end
```

Thus, combining this syntax with Rails' default rendering convention:

```ruby
class PostsController < ApplicationController
  garden_variety

  def create
    respond_to do |format|
      format.js{ super{} } # renders "app/views/posts/create.js.erb" on success
    end
  end

  def update
    respond_to do |format|
      format.js{ super{} } # renders "app/views/posts/update.js.erb" on success
    end
  end

  def destroy
    respond_to do |format|
      format.js{ super{} } # renders "app/views/posts/destroy.js.erb" on success
    end
  end

end
```

**Sidenote:** *garden_variety* automatically manages the life of flash
messages.  If a redirect is replaced with a render, the flash message
will be set such that it does not affect the next request.


### Authentication

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


### Form Objects

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
  garden_variety :new, :create # only generate #new and #create actions

  def create
    super{ redirect_to root_path } # redirect to home page on success
  end
end
```

In this example, only the `new` and `create` actions are generated by
the `garden_variety` macro.  The on-success behavior of `create` is
overridden to redirect to `root_path`, using the concise syntax
discussed in the [Integrating with SJR](#integrating-with-sjr) example.
The *garden_variety* controller helper methods all work as expected
because `RegistrationForm` responds to `assign_attributes` and `save`,
and has a default (nullary) constructor.


### Non-REST actions

You may also define any non-REST controller actions you wish (i.e.
actions other than: `index`, `show`, `new`, `create`, `edit`, `update`,
and `destroy`).  The controller helper methods *garden_variety* provides
may be useful when doing so.  However, before implementing a non-REST
controller action, consider if the behavior might be better implemented
as a REST action in a new controller.  For example, instead of the
following `published` action...

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
  self.model_class = Post
  garden_variety :index

  def find_collection
    super.where(published: true)
  end
end
```

Notice the call to `::model_class=`.  The model class for
`PublishedPostsController` is overridden as `Post` instead of derived as
`PublishedPost`.  And because of this override, the `@posts` instance
variable will be used instead of `@published_posts`.

This example may be somewhat contrived, but here is an excellent talk
from RailsConf which delves deeper into the principle:
[In Relentless Pursuit of REST](https://www.youtube.com/watch?v=HctYHe-YjnE)
([slides](https://speakerdeck.com/derekprior/in-relentless-pursuit-of-rest)).


## Installation

Add this line to your application's Gemfile:

```ruby
gem "garden_variety"
```

Then run:

```bash
$ bundle install
```

And finally, run the install generator:

```bash
$ rails generate garden:install
```

This will also run the Pundit install generator, if necessary.


## Contributing

Run `bin/test` to run the tests.


## License

[MIT License](MIT-LICENSE)
