# @!visibility private
module Garden
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def copy_locales
        directory "locales", "config/locales"
      end

      def install_pundit
        generate("pundit:install", "--skip")
      end
    end
  end
end
