# @!visibility private
module Garden
  module Generators
    class ScaffoldGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      argument :resource, type: :string

      # NOTE: an appropriate default value for template_engine (e.g.
      # :erb, or with the proper gem installed, :slim or :haml) is
      # inherited from Rails::Generators::Base
      class_option :template_engine

      # override +initialize+ because it is the only way to reliably
      # capture the raw input arguments in order to pass them on to
      # `rails generate resource` (Thor neglects to provide an accessor,
      # and ARGV is not populated during unit tests)
      def initialize(raw_args, raw_opts, config)
        @argv = raw_args + raw_opts
        super
      end

      def ensure_locales
        directory "../../install/templates/locales", "config/locales", skip: true
      end

      def generate_scaffolding
        generate("resource", *@argv)
        generate("#{options[:template_engine]}:scaffold", *@argv)
      end

      def inject_garden_variety_into_controller
        inject_into_class("app/controllers/#{resource.tableize}_controller.rb",
          "#{resource.tableize.camelize}Controller",
          "  garden_variety\n")
      end

      def generate_pundit_policy
        generate("pundit:policy", resource)
      end
    end
  end
end
