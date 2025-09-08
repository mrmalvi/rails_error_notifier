# frozen_string_literal: true

RailsErrorNotifier.configure do |config|
  # Slack + Discord
  config.slack_webhook   = ENV["SLACK_WEBHOOK_URL"] # "https://hooks.slack.com/services/T000/B000/XXXX"
  config.discord_webhook = ENV["DISCORD_WEBHOOK_URL"] # "https://discord.com/api/webhooks/1234567890/abcXYZ"

  # Email
  config.error_email_to   = ENV["ERROR_EMAIL_TO"]   # e.g. "dev-team@example.com"
  config.error_email_from = ENV["ERROR_EMAIL_FROM"] # e.g. "notifier@example.com"

  # WhatsApp (Twilio)
  config.twilio_sid   = ENV["TWILIO_SID"] #"AC1234567890abcdef1234567890abcd"
  config.twilio_token = ENV["TWILIO_TOKEN"] #"your_auth_token_here"
  config.twilio_from  = ENV["TWILIO_FROM"] #"+14155552671"
  config.twilio_to    = ENV["TWILIO_TO"] # "whatsapp:+919876543210"

  # Enable only in non-dev/test environments
  config.enabled = !Rails.env.development? && !Rails.env.test?
end
