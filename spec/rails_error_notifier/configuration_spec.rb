require "spec_helper"

RSpec.describe RailsErrorNotifier::Configuration do
  it "has default enabled true" do
    config = described_class.new
    expect(config.enabled).to be true
  end

  it "allows setting webhooks and enabled" do
    config = described_class.new
    config.slack_webhook = "slack_url"
    config.discord_webhook = "discord_url"
    config.enabled = false

    expect(config.slack_webhook).to eq("slack_url")
    expect(config.discord_webhook).to eq("discord_url")
    expect(config.enabled).to be false
  end
end
