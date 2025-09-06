require "spec_helper"

RSpec.describe RailsErrorNotifier::Notifier do
  let(:exception) { StandardError.new("Something went wrong") }

  before do
    RailsErrorNotifier.configure do |config|
      config.slack_webhook   = "http://example.com/slack"
      config.discord_webhook = "http://example.com/discord"
      config.enabled         = true
    end

    stub_request(:post, "http://example.com/slack")
      .with(headers: { "Content-Type" => "application/json" })
      .to_return(status: 200, body: "", headers: {})

    stub_request(:post, "http://example.com/discord")
      .with(headers: { "Content-Type" => "application/json" })
      .to_return(status: 200, body: "", headers: {})
  end

  describe "basic delivery" do
    it "sends error to Slack and Discord" do
      described_class.new(exception, user_id: 123).deliver

      expect(a_request(:post, "http://example.com/slack")).to have_been_made
      expect(a_request(:post, "http://example.com/discord")).to have_been_made
    end

    it "does not send if config is disabled" do
      RailsErrorNotifier.configuration.enabled = false
      described_class.new(exception).deliver

      expect(a_request(:post, "http://example.com/slack")).not_to have_been_made
      expect(a_request(:post, "http://example.com/discord")).not_to have_been_made
    end

    it "does not fail if webhooks are nil" do
      RailsErrorNotifier.configuration.slack_webhook = nil
      RailsErrorNotifier.configuration.discord_webhook = nil

      expect { described_class.new(exception).deliver }.not_to raise_error
    end
  end

  describe "payload content" do
    it "includes context and backtrace in payload" do
      described_class.new(exception, user: "test_user").deliver

      expect(
        a_request(:post, "http://example.com/slack")
          .with(body: /"error":"Something went wrong".*"context":\{"user":"test_user"\}/)
      ).to have_been_made

      expect(
        a_request(:post, "http://example.com/discord")
          .with(body: /"error":"Something went wrong".*"context":\{"user":"test_user"\}/)
      ).to have_been_made
    end

    it "handles exception with nil backtrace" do
      exception = StandardError.new("No backtrace")
      allow(exception).to receive(:backtrace).and_return(nil)

      expect { described_class.new(exception).deliver }.not_to raise_error

      expect(
        a_request(:post, "http://example.com/slack")
          .with(body: /"error":"No backtrace".*"context":\{\}/)
      ).to have_been_made

      expect(
        a_request(:post, "http://example.com/discord")
          .with(body: /"error":"No backtrace".*"context":\{\}/)
      ).to have_been_made
    end

    it "supports multiple context values" do
      described_class.new(exception, user: "alice", role: "admin").deliver

      expect(
        a_request(:post, "http://example.com/slack")
          .with(body: /"context":\{"user":"alice","role":"admin"\}/)
      ).to have_been_made

      expect(
        a_request(:post, "http://example.com/discord")
          .with(body: /"context":\{"user":"alice","role":"admin"\}/)
      ).to have_been_made
    end
  end

  describe "robustness" do
    it "does not raise if Slack webhook fails" do
      stub_request(:post, "http://example.com/slack").to_return(status: 500)
      expect { described_class.new(exception).deliver }.not_to raise_error
    end

    it "does not raise if Discord webhook fails" do
      stub_request(:post, "http://example.com/discord").to_return(status: 500)
      expect { described_class.new(exception).deliver }.not_to raise_error
    end

    it "sends only once for multiple exceptions" do
      3.times { described_class.new(exception).deliver }

      expect(a_request(:post, "http://example.com/slack")).to have_been_made.times(3)
      expect(a_request(:post, "http://example.com/discord")).to have_been_made.times(3)
    end
  end
end
