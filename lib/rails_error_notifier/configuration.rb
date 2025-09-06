module RailsErrorNotifier
  class Configuration
    attr_accessor :slack_webhook, :discord_webhook, :enabled

    def initialize
      @enabled = true
    end
  end
end
