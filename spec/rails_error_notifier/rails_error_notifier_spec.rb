require "spec_helper"
require "webmock/rspec"
require "rails"
require "rack/test"

# require_relative "../lib/rails_error_notifier"

RSpec.describe RailsErrorNotifier do
  let(:exception) { StandardError.new("Something went wrong") }

  before do
    # Stub Slack & Discord
    stub_request(:post, "http://example.com/slack").to_return(status: 200, body: "", headers: {})
    stub_request(:post, "http://example.com/discord").to_return(status: 200, body: "", headers: {})

    # Stub Twilio WhatsApp API
    stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/sid123/Messages.json")
      .with(
        body: hash_including(
          "Body" => a_string_including("Error"),
          "From" => "whatsapp:+14150000000",
          "To"   => "whatsapp:+919876543210"
        ),
        headers: {
          "Authorization" => "Basic c2lkMTIzOnRva2VuMTIz", # sid123:token123 base64
          "Content-Type"  => "application/x-www-form-urlencoded"
        }
      )
      .to_return(status: 200, body: "", headers: {})

    RailsErrorNotifier.configure do |config|
      config.slack_webhook   = "http://example.com/slack"
      config.discord_webhook = "http://example.com/discord"
      config.enabled         = true

      config.twilio_sid   = "sid123"
      config.twilio_token = "token123"
      config.twilio_from  = "+14150000000"
      config.twilio_to    = "+919876543210"
    end
  end

  describe RailsErrorNotifier::Configuration do
    it "is enabled by default" do
      expect(RailsErrorNotifier::Configuration.new.enabled).to be true
    end
  end

  describe RailsErrorNotifier::Notifier do
    it "sends payload to Slack, Discord, and WhatsApp" do
      expect {
        described_class.new(exception, context: { user: "tester" }).deliver
      }.not_to raise_error

      expect(WebMock).to have_requested(:post, "http://example.com/slack").once
      expect(WebMock).to have_requested(:post, "http://example.com/discord").once
      expect(WebMock).to have_requested(
        :post,
        "https://api.twilio.com/2010-04-01/Accounts/sid123/Messages.json"
      ).once
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
      expect(WebMock).to have_requested(:post, "http://example.com/slack").once
      expect(WebMock).to have_requested(:post, "http://example.com/discord").once
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
