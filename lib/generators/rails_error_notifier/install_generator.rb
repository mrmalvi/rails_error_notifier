# lib/generators/rails_error_notifier/install_generator.rb
require "rails/generators"

module RailsErrorNotifier
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a RailsErrorNotifier initializer in config/initializers"

      def copy_initializer
        template "rails_error_notifier.rb", "config/initializers/rails_error_notifier.rb"
      end
    end
  end
end
