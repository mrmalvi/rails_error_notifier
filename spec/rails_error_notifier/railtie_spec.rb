require "spec_helper"
require "rails_error_notifier/railtie"

RSpec.describe RailsErrorNotifier::Railtie do
  it "adds middleware to Rails app" do
    app = Class.new(Rails::Application) do
      config.eager_load = false
    end

    expect(app.middleware).to receive(:use).with(RailsErrorNotifier::Middleware)
    RailsErrorNotifier::Railtie.initializers.first.block.call(app)
  end
end
