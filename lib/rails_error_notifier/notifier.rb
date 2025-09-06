require "net/http"
require "json"

module RailsErrorNotifier
  class Notifier
    MAX_FIELD_VALUE = 1024
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

    def truncate_for_discord(text)
      text[0, MAX_FIELD_VALUE - 10] # leave room for ``` block
    end

    def send_to_webhook(url, payload)
      return unless url
      uri = URI(url)

      data = if url.include?("hooks.slack.com")
        { text: "#{payload[:error]}\n#{payload[:backtrace].join("\n")}" }
      else
        backtrace_text = truncate_for_discord(payload[:backtrace].first(10).join("\n"))
        context_text   = truncate_for_discord(payload[:context].inspect)
        data = {
          name: "RailsErrorNotifier", # webhook display name
          embeds: [
            {
              title: "🚨 Error Occurred",
              description: payload[:error],
              color: 0xFF0000,
              fields: [
                {
                  name: "Backtrace",
                  value: "```\n#{backtrace_text}\n```",
                  inline: false
                },
                {
                  name: "Context",
                  value: "```\n#{context_text}\n```",
                  inline: false
                }
              ],
              timestamp: Time.now.utc.iso8601
            }
          ]
        }
      end

      Net::HTTP.post(uri, data.to_json, "Content-Type" => "application/json")
    end
  end
end
