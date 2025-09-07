require "net/http"
require "json"
begin
  require 'twilio-ruby'
rescue LoadError
  warn "Twilio gem not installed, skipping Twilio integration."
end

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
        backtrace: exception.backtrace || ["No backtrace"],
        context: context || {}
      }

      # Slack + Discord
      send_to_webhook(RailsErrorNotifier.configuration.slack_webhook, payload)
      send_to_webhook(RailsErrorNotifier.configuration.discord_webhook, payload)

      # Email (Rails Mailer)
      send_to_email(payload)

      # WhatsApp (Twilio)
      send_to_whatsapp(payload)
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
        backtrace_text = truncate_for_discord((payload[:backtrace] || ["No backtrace"]).first(10).join("\n"))
        context_text   = truncate_for_discord(payload[:context].inspect)
        {
          username: "RailsErrorNotifier",
          embeds: [
            {
              title: "🚨 Error Occurred",
              description: payload[:error],
              color: 0xFF0000,
              fields: [
                { name: "Backtrace", value: "```\n#{backtrace_text}\n```", inline: false },
                { name: "Context",   value: "```\n#{context_text}\n```",   inline: false }
              ],
              timestamp: Time.now.utc.iso8601
            }
          ]
        }
      end

      Net::HTTP.post(uri, data.to_json, "Content-Type" => "application/json")
    rescue => e
      warn "[RailsErrorNotifier] Slack/Discord delivery failed: #{e.message}"
      nil
    end

    def send_to_email(payload)
      return unless defined?(RailsErrorNotifier::ErrorNotifierMailer)

      RailsErrorNotifier::ErrorNotifierMailer.error_notification(
        error: payload[:error],
        backtrace: payload[:backtrace],
        context: payload[:context]
      ).deliver_now
    rescue => e
      warn "[RailsErrorNotifier] Email delivery failed: #{e.message}"
      nil
    end

    def send_to_whatsapp(payload)
      cfg = RailsErrorNotifier.configuration
      return unless cfg&.twilio_sid && cfg&.twilio_token

      client = Twilio::REST::Client.new(cfg.twilio_sid, cfg.twilio_token)

      message = "🚨 Error: #{payload[:error]}\n" \
                "Backtrace: #{payload[:backtrace].first}\n" \
                "Context: #{payload[:context].inspect}"

      client.messages.create(
        from: "whatsapp:#{cfg.twilio_from}",
        to:   "whatsapp:#{cfg.twilio_to}",
        body: message
      )
    rescue => e
      warn "[RailsErrorNotifier] WhatsApp delivery failed: #{e.message}"
      nil
    end
  end
end
