# spec/rails_error_notifier/rails_error_notifier_spec.rb
require "webmock/rspec"

RSpec.describe RailsErrorNotifier do
  before do
    # Stub Slack & Discord
    stub_request(:post, "http://example.com/slack").to_return(status: 200, body: "", headers: {})
    stub_request(:post, "http://example.com/discord").to_return(status: 200, body: "", headers: {})

    # Stub Twilio WhatsApp API
    stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/sid123/Messages.json")
      .with(
        body: hash_including(
          "Body" => a_string_including("Error"),
          "From" => "whatsapp:+14150000000",
          "To"   => "whatsapp:+919876543210"
        ),
        headers: {
          "Authorization" => "Basic c2lkMTIzOnRva2VuMTIz", # sid123:token123 base64
          "Content-Type"  => "application/x-www-form-urlencoded"
        }
      )
      .to_return(status: 200, body: "", headers: {})

    RailsErrorNotifier.configure do |cfg|
      cfg.slack_webhook   = "http://example.com/slack"
      cfg.discord_webhook = "http://example.com/discord"

      cfg.twilio_sid   = "sid123"
      cfg.twilio_token = "token123"
      cfg.twilio_from  = "+14150000000"
      cfg.twilio_to    = "+919876543210"
    end
  end

  let(:exception) { StandardError.new("Something went wrong") }

  describe RailsErrorNotifier::Notifier do
    it "sends payload to Slack, Discord, and WhatsApp" do
      expect {
        described_class.new(exception, context: { user: "tester" }).deliver
      }.not_to raise_error

      expect(WebMock).to have_requested(:post, "http://example.com/slack").once
      expect(WebMock).to have_requested(:post, "http://example.com/discord").once
      expect(WebMock).to have_requested(
        :post,
        "https://api.twilio.com/2010-04-01/Accounts/sid123/Messages.json"
      ).once
    end

    it "handles nil backtrace" do
      exception.set_backtrace(nil)
      expect {
        described_class.new(exception).deliver
      }.not_to raise_error
    end

    it "sends email notification" do
      # Configure email settings
      RailsErrorNotifier.configure do |cfg|
        cfg.error_email_to = "test@example.com"
        cfg.error_email_from = "errors@example.com"
      end

      # Mock the mailer to avoid template issues in tests
      mailer_double = double("ErrorNotifierMailer")
      allow(RailsErrorNotifier::ErrorNotifierMailer).to receive(:error_notification).and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_now)

      described_class.new(exception, context: { user: "tester" }).deliver

      expect(RailsErrorNotifier::ErrorNotifierMailer).to have_received(:error_notification).with(
        error: "Something went wrong",
        backtrace: ["No backtrace"],
        context: { context: { user: "tester" } }
      )
      expect(mailer_double).to have_received(:deliver_now)
    end

    it "renders email templates with correct content" do
      # Configure email settings
      RailsErrorNotifier.configure do |cfg|
        cfg.error_email_to = "test@example.com"
        cfg.error_email_from = "errors@example.com"
      end

      # Create a test exception with backtrace
      test_exception = StandardError.new("Test error message")
      test_exception.set_backtrace(["line1.rb:10:in `method1'", "line2.rb:5:in `method2'"])

      # Create mailer instance and render templates
      mailer = RailsErrorNotifier::ErrorNotifierMailer.error_notification(
        error: test_exception.message,
        backtrace: test_exception.backtrace,
        context: { user: "test_user", action: "test_action" }
      )

      # Test HTML template
      html_body = mailer.html_part.body.to_s
      expect(html_body).to include("🚨 Error Notification")
      expect(html_body).to include("Test error message")
      expect(html_body).to include("line1.rb:10:in `method1&#39;")
      expect(html_body).to include("line2.rb:5:in `method2&#39;")
      expect(html_body).to include("test_user")
      expect(html_body).to include("test_action")
      expect(html_body).to include("RailsErrorNotifier")

      # Test text template
      text_body = mailer.text_part.body.to_s
      expect(text_body).to include("🚨 ERROR NOTIFICATION")
      expect(text_body).to include("Test error message")
      expect(text_body).to include("line1.rb:10:in `method1'")
      expect(text_body).to include("line2.rb:5:in `method2'")
      expect(text_body).to include("test_user")
      expect(text_body).to include("test_action")
      expect(text_body).to include("RailsErrorNotifier")

      # Test email headers
      expect(mailer.to).to eq(["test@example.com"])
      expect(mailer.from).to eq(["errors@example.com"])
      expect(mailer.subject).to include("Test error message")
    end

    it "handles nil backtrace in email templates" do
      # Configure email settings
      RailsErrorNotifier.configure do |cfg|
        cfg.error_email_to = "test@example.com"
        cfg.error_email_from = "errors@example.com"
      end

      # Create mailer instance with nil backtrace
      mailer = RailsErrorNotifier::ErrorNotifierMailer.error_notification(
        error: "Test error",
        backtrace: nil,
        context: { user: "test_user" }
      )

      # Test HTML template with nil backtrace
      html_body = mailer.html_part.body.to_s
      expect(html_body).to include("Test error")
      expect(html_body).to include("Backtrace")
      expect(html_body).to include("<pre style=") # Empty backtrace section

      # Test text template with nil backtrace
      text_body = mailer.text_part.body.to_s
      expect(text_body).to include("Test error")
      expect(text_body).to include("Backtrace:")
      expect(text_body).to include("--------")
    end
  end

  describe RailsErrorNotifier::Middleware do
    let(:app) do
      proc do |env|
        raise StandardError, "middleware failure" if env["PATH_INFO"] == "/fail"
        [200, { "Content-Type" => "text/plain" }, ["ok"]]
      end
    end

    let(:middleware) { described_class.new(app) }

    it "notifies when exception occurs" do
      expect {
        middleware.call("PATH_INFO" => "/fail")
      }.to raise_error(StandardError, "middleware failure")

      expect(WebMock).to have_requested(:post, "http://example.com/slack").once
      expect(WebMock).to have_requested(:post, "http://example.com/discord").once
    end

    it "passes through on success" do
      status, headers, body = middleware.call("PATH_INFO" => "/success")
      expect(status).to eq(200)
      expect(body).to eq(["ok"])
    end
  end
end
