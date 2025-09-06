require "net/http"
require "json"

module RailsErrorNotifier
  class Notifier
    attr_reader :exception, :context

    def initialize(exception, context = {})
      @exception = exception
      @context   = context
    end

    def deliver
      return unless RailsErrorNotifier.configuration&.enabled

      payload = {
        error: exception.message,
        backtrace: exception.backtrace,
        context: context
      }

      send_to_webhook(RailsErrorNotifier.configuration.slack_webhook, payload)
      send_to_webhook(RailsErrorNotifier.configuration.discord_webhook, payload)
    end

    private

    def send_to_webhook(url, payload)
      return unless url
      uri = URI(url)

      data = if url.include?("hooks.slack.com")
        { text: "#{payload[:error]}\n#{payload[:backtrace].join("\n")}" }
      else
        payload
      end

      Net::HTTP.post(uri, data.to_json, "Content-Type" => "application/json")
    end
  end
end
