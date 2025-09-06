require "spec_helper"
require "rails"
require "rack/test"

# require_relative "../lib/rails_error_notifier"

RSpec.describe RailsErrorNotifier do
  let(:exception) { StandardError.new("Something went wrong") }

  before do
    RailsErrorNotifier.configure do |config|
      config.slack_webhook   = "http://example.com/slack"
      config.discord_webhook = "http://example.com/discord"
      config.enabled         = true
    end

    stub_request(:post, "http://example.com/slack")
      .to_return(status: 200)
    stub_request(:post, "http://example.com/discord")
      .to_return(status: 200)
  end

  describe RailsErrorNotifier::Configuration do
    it "is enabled by default" do
      expect(RailsErrorNotifier::Configuration.new.enabled).to be true
    end
  end

  describe RailsErrorNotifier::Notifier do
    it "sends payload to Slack and Discord" do
      described_class.new(exception, user: "tester").deliver
      expect(a_request(:post, "http://example.com/slack")).to have_been_made
      expect(a_request(:post, "http://example.com/discord")).to have_been_made
    end

    it "handles nil backtrace" do
      allow(exception).to receive(:backtrace).and_return(nil)
      expect { described_class.new(exception).deliver }.not_to raise_error
    end

    it "does not send if disabled" do
      RailsErrorNotifier.configuration.enabled = false
      described_class.new(exception).deliver
      expect(a_request(:post, "http://example.com/slack")).not_to have_been_made
    end
  end

  describe RailsErrorNotifier::Middleware do
    include Rack::Test::Methods

    let(:app) { Rack::Builder.new { run ->(_env) { [200, {}, ["OK"]] } }.to_app }

    it "calls downstream app normally" do
      middleware = RailsErrorNotifier::Middleware.new(app)
      status, = middleware.call("PATH_INFO" => "/test")
      expect(status).to eq(200)
    end

    it "notifies when exception occurs" do
      failing_app = ->(_env) { raise exception }
      middleware = RailsErrorNotifier::Middleware.new(failing_app)
      expect { middleware.call("PATH_INFO" => "/fail") }.to raise_error(StandardError)
      expect(a_request(:post, "http://example.com/slack")).to have_been_made
      expect(a_request(:post, "http://example.com/discord")).to have_been_made
    end
  end

  if defined?(Rails)
    describe RailsErrorNotifier::Railtie do
      it "adds middleware to Rails app" do
        app = Class.new(Rails::Application) do
          config.eager_load = false
        end
        expect(app.middleware).to receive(:use).with(RailsErrorNotifier::Middleware)
        RailsErrorNotifier::Railtie.initializers.first.block.call(app)
      end
    end
  end

  describe ".configure" do
    it "yields configuration" do
      RailsErrorNotifier.configure { |config| config.enabled = false }
      expect(RailsErrorNotifier.configuration.enabled).to be false
    end
  end

  describe ".notify" do
    it "calls Notifier.deliver" do
      notifier = instance_double("RailsErrorNotifier::Notifier")
      expect(RailsErrorNotifier::Notifier).to receive(:new).with(exception, {}).and_return(notifier)
      expect(notifier).to receive(:deliver)
      RailsErrorNotifier.notify(exception)
    end
  end
end
