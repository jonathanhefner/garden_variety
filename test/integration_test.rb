require "test_helper"
require "garden_variety"


Post.class_eval do
  validates :title, exclusion: { in: ["BAD!"] }
end

PostPolicy.class_eval do
  class_attribute :allow_all

  [:index?, :show?, :new?, :create?, :edit?, :update?, :destroy?].each do |m|
    define_method(m) do
      allow_all
    end
  end

  class_attribute :permitted_attributes
end

PostPolicy::Scope.class_eval do
  class_attribute :allow_ids

  undef resolve
  def resolve
    allow_ids ? scope.where(id: allow_ids) : scope.all
  end
end

PostsController.class_eval do
  protect_from_forgery with: :null_session

  [:create, :update, :destroy].each do |action|
    define_method(action) do
      if request.headers["X-Test-redirect_to"]
        super(){ redirect_to request.headers["X-Test-redirect_to"] }
      else
        super()
      end
    end
  end

  def list_resources
    response.headers["X-Test-list_resources"] = "test"
    super
  end

  def find_resource
    response.headers["X-Test-find_resource"] = "test"
    super
  end

  def new_resource
    response.headers["X-Test-new_resource"] = "test"
    super
  end
end


class IntegrationTest < ActionDispatch::IntegrationTest

  fixtures :posts

  AN_ID = Post.pluck(:id).first

  setup do
    Rails.application.config.action_dispatch.show_exceptions = false

    PostPolicy.allow_all = true
    PostPolicy.permitted_attributes = [:title]
    PostPolicy::Scope.allow_ids = nil
  end

  def test_index
    get posts_path
    assert_response :success
    assert_equal "test", response.headers["X-Test-list_resources"]
    Post.pluck(:id).each do |id|
      assert_select "a[href=?]", post_path(id)
    end
  end

  def test_index_scoped
    PostPolicy::Scope.allow_ids = Post.pluck(:id) - [AN_ID]
    get posts_path
    assert_response :success
    assert_select "a[href=?]", post_path(AN_ID), count: 0
  end

  def test_index_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) { get posts_path }
  end

  def test_show
    get post_path(AN_ID)
    assert_response :success
    assert_equal "test", response.headers["X-Test-find_resource"]
    assert_select "a[href=?]", edit_post_path(AN_ID)
  end

  def test_show_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) { get post_path(AN_ID) }
  end

  def test_new
    get new_post_path
    assert_response :success
    assert_equal "test", response.headers["X-Test-new_resource"]
    assert_select "form[action=?]", posts_path
  end

  def test_new_with_params
    get new_post_path, params: { post: { title: "POPULATED!" } }
    assert_response :success
    assert_select 'input[name="post[title]"][value=?]', "POPULATED!"
    refute Post.where(title: "POPULATED!").exists?
  end

  def test_new_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) { get new_post_path }
  end

  def test_create
    post posts_path, params: { post: { title: "NEW!" } }
    assert_equal "test", response.headers["X-Test-new_resource"]
    new_post = Post.order(:created_at).last
    assert_redirected_to new_post
    assert_equal "NEW!", new_post.title
  end

  def test_create_with_callback
    expected_path = "/?test"
    post posts_path, params: { post: { title: "NEW!" } },
      headers: { "X-Test-redirect_to" => expected_path }
    assert_redirected_to expected_path
    assert_equal "NEW!", Post.order(:created_at).last.title
  end

  def test_create_validation_fails
    post posts_path, params: { post: { title: "BAD!" } }
    assert_response :success
    assert_select "form[action=?]", posts_path
    refute Post.where(title: "BAD!").exists?
  end

  def test_create_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      post posts_path, params: { post: { title: "NEW!" } }
    end
    refute Post.where(title: "NEW!").exists?
  end

  def test_edit
    get edit_post_path(AN_ID)
    assert_response :success
    assert_equal "test", response.headers["X-Test-find_resource"]
    assert_select "form[action=?]", post_path(AN_ID)
  end

  def test_edit_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) { get edit_post_path(AN_ID) }
  end

  def test_update
    put post_path(AN_ID), params: { post: { title: "UPDATED!" } }
    assert_equal "test", response.headers["X-Test-find_resource"]
    assert_redirected_to post_path(AN_ID)
    assert_equal "UPDATED!", Post.find(AN_ID).title
  end

  def test_update_with_callback
    expected_path = "/?test"
    put post_path(AN_ID), params: { post: { title: "UPDATED!" } },
      headers: { "X-Test-redirect_to" => expected_path }
    assert_redirected_to expected_path
    assert_equal "UPDATED!", Post.find(AN_ID).title
  end

  def test_update_validation_fails
    put post_path(AN_ID), params: { post: { title: "BAD!" } }
    assert_response :success
    assert_select "form[action=?]", post_path(AN_ID)
    refute_equal "BAD!", Post.find(AN_ID).title
  end

  def test_update_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      put post_path(AN_ID), params: { post: { title: "UPDATED!" } }
    end
    refute_equal "UPDATED!", Post.find(AN_ID).title
  end

  def test_destroy
    delete post_path(AN_ID)
    assert_equal "test", response.headers["X-Test-find_resource"]
    assert_redirected_to posts_path
    refute Post.exists?(AN_ID)
  end

  def test_destroy_with_callback
    expected_path = "/?test"
    delete post_path(AN_ID), headers: { "X-Test-redirect_to" => expected_path }
    assert_redirected_to expected_path
    refute Post.exists?(AN_ID)
  end

  def test_destroy_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      delete post_path(AN_ID)
    end
    assert Post.exists?(AN_ID)
  end

  def test_strong_params
    PostPolicy.permitted_attributes = []
    put post_path(AN_ID), params: { post: { title: "UNPERMITTED!" } }
    follow_redirect!
    assert_response :success
    refute_equal "UNPERMITTED!", Post.find(AN_ID).title
  end

end
