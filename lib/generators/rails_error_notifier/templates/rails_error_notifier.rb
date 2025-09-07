# frozen_string_literal: true

RailsErrorNotifier.configure do |config|
  # Slack + Discord
  config.slack_webhook   = ENV["SLACK_WEBHOOK_URL"]
  config.discord_webhook = ENV["DISCORD_WEBHOOK_URL"]

  # Email
  config.error_email_to   = ENV["ERROR_EMAIL_TO"]   # e.g. "dev-team@example.com"
  config.error_email_from = ENV["ERROR_EMAIL_FROM"] # e.g. "notifier@example.com"

  # WhatsApp (Twilio)
  config.twilio_sid   = ENV["TWILIO_SID"]
  config.twilio_token = ENV["TWILIO_TOKEN"]
  config.twilio_from  = ENV["TWILIO_FROM"]
  config.twilio_to    = ENV["TWILIO_TO"]

  # Enable only in non-dev/test environments
  config.enabled = !Rails.env.development? && !Rails.env.test?
end
