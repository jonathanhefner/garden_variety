require "test_helper"
require "garden_variety"


Post.class_eval do
  validates :title, exclusion: { in: ["BAD!"] }
  before_destroy{|post| throw(:abort) if post.title == "PERMANENT!" }
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
      elsif request.headers["X-Test-render_default"]
        super(){}
      else
        super()
      end
    end
  end

  def find_collection
    response.headers["X-Test-find_collection"] = "test"
    super
  end

  def find_model
    response.headers["X-Test-find_model"] = "test"
    super
  end

  def new_model
    response.headers["X-Test-new_model"] = "test"
    super
  end

  def flash_message(status)
    "test flash_message"
  end
end


class IntegrationTest < ActionDispatch::IntegrationTest

  setup do
    Rails.application.config.action_dispatch.show_exceptions = false

    PostPolicy.allow_all = true
    PostPolicy.permitted_attributes = [:title]
    PostPolicy::Scope.allow_ids = nil

    @post_id = Post.pluck(:id).first
  end

  def test_index
    get posts_path
    assert_response :success
    assert_used :find_collection
    Post.pluck(:id).each do |id|
      assert_select "a[href=?]", post_path(id)
    end
  end

  def test_index_scoped
    PostPolicy::Scope.allow_ids = Post.pluck(:id) - [@post_id]
    get posts_path
    assert_response :success
    assert_select "a[href=?]", post_path(@post_id), count: 0
  end

  def test_index_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      get posts_path
    end
  end

  def test_show
    get post_path(@post_id)
    assert_response :success
    assert_used :find_model
    assert_rendered_show @post_id
  end

  def test_show_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      get post_path(@post_id)
    end
  end

  def test_new
    get new_post_path
    assert_response :success
    assert_used :new_model
    assert_rendered_new
  end

  def test_new_with_params
    get new_post_path, params: { post: { title: "POPULATED!" } }
    assert_response :success
    assert_rendered_new
    assert_select 'input[name="post[title]"][value=?]', "POPULATED!"
    refute Post.where(title: "POPULATED!").exists?
  end

  def test_new_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      get new_post_path
    end
  end

  def test_create
    post posts_path, params: { post: { title: "NEW!" } }
    assert_used :new_model
    new_post = Post.order(:created_at).last
    assert_redirected_to new_post
    assert_flash_message :success
    assert_equal "NEW!", new_post.title
  end

  def test_create_with_custom_redirect
    expected_path = "/?test"
    post posts_path, params: { post: { title: "NEW!" } },
      headers: { "X-Test-redirect_to" => expected_path }
    assert_redirected_to expected_path
    assert_flash_message :success
    assert_equal "NEW!", Post.order(:created_at).last.title
  end

  def test_create_with_sjr
    post "#{posts_path}.js", params: { post: { title: "SJR!" } },
      headers: { "X-Test-render_default" => true }
    assert_response :success
    assert_flash_message :success, now: true
    assert_rendered_sjr :create
    assert_equal "SJR!", Post.order(:created_at).last.title
  end

  def test_create_validation_fails
    post posts_path, params: { post: { title: "BAD!" } }
    assert_response :success
    assert_flash_message :error, now: true
    assert_rendered_new
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
    get edit_post_path(@post_id)
    assert_response :success
    assert_used :find_model
    assert_rendered_edit(@post_id)
  end

  def test_edit_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      get edit_post_path(@post_id)
    end
  end

  def test_update
    put post_path(@post_id), params: { post: { title: "UPDATED!" } }
    assert_used :find_model
    assert_redirected_to post_path(@post_id)
    assert_flash_message :success
    assert_equal "UPDATED!", Post.find(@post_id).title
  end

  def test_update_with_custom_redirect
    expected_path = "/?test"
    put post_path(@post_id), params: { post: { title: "UPDATED!" } },
      headers: { "X-Test-redirect_to" => expected_path }
    assert_redirected_to expected_path
    assert_flash_message :success
    assert_equal "UPDATED!", Post.find(@post_id).title
  end

  def test_update_with_sjr
    put "#{post_path(@post_id)}.js", params: { post: { title: "SJR!" } },
      headers: { "X-Test-render_default" => true }
    assert_response :success
    assert_flash_message :success, now: true
    assert_rendered_sjr :update
    assert_equal "SJR!", Post.find(@post_id).title
  end

  def test_update_validation_fails
    put post_path(@post_id), params: { post: { title: "BAD!" } }
    assert_response :success
    assert_rendered_edit(@post_id)
    assert_flash_message :error, now: true
    refute_equal "BAD!", Post.find(@post_id).title
  end

  def test_update_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      put post_path(@post_id), params: { post: { title: "UPDATED!" } }
    end
    refute_equal "UPDATED!", Post.find(@post_id).title
  end

  def test_destroy
    delete post_path(@post_id)
    assert_used :find_model
    assert_redirected_to posts_path
    assert_flash_message :success
    refute Post.exists?(@post_id)
  end

  def test_destroy_with_custom_redirect
    expected_path = "/?test"
    delete post_path(@post_id), headers: { "X-Test-redirect_to" => expected_path }
    assert_redirected_to expected_path
    assert_flash_message :success
    refute Post.exists?(@post_id)
  end

  def test_destroy_with_sjr
    delete "#{post_path(@post_id)}.js", headers: { "X-Test-render_default" => true }
    assert_response :success
    assert_flash_message :success, now: true
    assert_rendered_sjr :destroy
    refute Post.exists?(@post_id)
  end

  def test_destroy_fails
    Post.find(@post_id).update(title: "PERMANENT!")
    delete post_path(@post_id)
    assert_response :success
    assert_rendered_show(@post_id)
    assert_flash_message :error, now: true
    assert Post.exists?(@post_id)
  end

  def test_destroy_forbidden
    PostPolicy.allow_all = false
    assert_raises(Pundit::NotAuthorizedError) do
      delete post_path(@post_id)
    end
    assert Post.exists?(@post_id)
  end

  def test_strong_params
    PostPolicy.permitted_attributes = []
    put post_path(@post_id), params: { post: { title: "UNPERMITTED!" } }
    follow_redirect!
    assert_response :success
    refute_equal "UNPERMITTED!", Post.find(@post_id).title
  end

  private

  def assert_used(name)
    assert_equal "test", response.headers["X-Test-#{name}"]
  end

  def assert_flash_message(key, now: false)
    assert_match "test flash_message", flash[key]
    # flash and flash.now values are combined in `flash` attribute, so
    # distinguish them by checking values to keep for next request
    keep = flash.to_session_value.to_h["flashes"].to_h
    if now
      refute_includes keep, key.to_s
    else
      assert_includes keep, key.to_s
    end
  end

  def assert_rendered_show(post_id)
    assert_select "a[href=?]", edit_post_path(post_id)
    assert_select "a[href=?]", posts_path
  end

  def assert_rendered_new
    assert_select "form[action=?]", posts_path
  end

  def assert_rendered_edit(post_id)
    assert_select "form[action=?]", post_path(post_id)
  end

  def assert_rendered_sjr(action)
    assert_includes %w[text/javascript application/javascript], response.media_type
    assert_match "alert(\"#{action}\")", response.body
  end

end
