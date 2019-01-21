module GardenVariety
  # @!visibility private
  class Railtie < ::Rails::Railtie
    # Render 404 on Pundit::NotAuthorizedError in production.  (Helpful
    # error pages will still be shown in development.)  Code 404 is used
    # because it is more discreet than 403, because it is explicitly
    # allowed by RFC7231 (https://tools.ietf.org/html/rfc7231#section-6.5.3),
    # and because Rails includes a default 404 page, but not a 403 page.
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] ||= :not_found

    initializer "garden_variety" do |app|
      ActiveSupport.on_load :action_controller do
        include GardenVariety::CurrentUserStub unless instance_methods.include?(:current_user)
        include GardenVariety::Controller
      end
    end
  end
end
