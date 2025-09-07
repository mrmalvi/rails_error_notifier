module RailsErrorNotifier
  class Configuration
    attr_accessor :slack_webhook,
                  :discord_webhook,
                  :error_email_to,
                  :error_email_from,
                  :twilio_sid,
                  :twilio_token,
                  :twilio_from,
                  :twilio_to,
                  :enabled

    def initialize
      @enabled = true
    end
  end
end
