require "action_mailer"
module RailsErrorNotifier
  class ErrorNotifierMailer < ActionMailer::Base
    default from: -> { RailsErrorNotifier.configuration.error_email_from || "errors@example.com" }

    def error_notification(error:, backtrace:, context:)
      @error     = error
      @backtrace = backtrace
      @context   = context

      # Set the view path to the gem's templates
      view_path = File.join(File.dirname(__FILE__), "views")
      prepend_view_path(view_path) if File.exist?(view_path)

      mail(
        to: RailsErrorNotifier.configuration.error_email_to || "devs@example.com",
        subject: "[RailsErrorNotifier] #{error.truncate(50)}"
      )
    end
  end
end
