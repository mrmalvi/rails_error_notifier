require "rails"

module RailsErrorNotifier
  class Railtie < Rails::Railtie
    initializer "rails_error_notifier.configure_middleware" do |app|
      app.middleware.use RailsErrorNotifier::Middleware
    end
  end
end
