# frozen_string_literal: true

# This is the initializer for RailsErrorNotifier
RailsErrorNotifier.configure do |config|
  # Configure your Slack and Discord webhooks via ENV variables
  config.slack_webhook   = ENV["SLACK_WEBHOOK_URL"]
  config.discord_webhook = ENV["DISCORD_WEBHOOK_URL"]

  # Optional: disable in development/test
  config.enabled = !Rails.env.development? && !Rails.env.test?
end
