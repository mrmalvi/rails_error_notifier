# 🚨 RailsErrorNotifier

RailsErrorNotifier is a Ruby gem that automatically captures and notifies about errors in your Rails applications.
It integrates with **Slack** and **Discord** out of the box, so you never miss a critical error in production.

---

## ✨ Features
- 🔥 Capture unhandled exceptions in Rails automatically via Rack middleware.
- 📩 Send error notifications to **Slack** and **Discord**.
- ⚙️ Easy configuration through Rails initializers.
- 📝 Add custom context (e.g., current user, request path).
- 🛡️ Safe when disabled (no crashes if webhooks are missing).

---

## 📦 Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'rails_error_notifier', git: 'https://github.com/mrmalvi/rails_error_notifier.git'
```

Then execute:

```bash
bundle install
```

Or install it manually:

```bash
gem install rails_error_notifier
```

---

## ⚙️ Configuration

Generate an initializer in your Rails app:

```bash
bin/rails generate rails_error_notifier:install
```

This creates `config/initializers/rails_error_notifier.rb`:

```ruby
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
```

---

## 🚀 Usage

### Automatic Error Notifications
Once installed, `RailsErrorNotifier` automatically hooks into Rails middleware.
Whenever an exception occurs, a notification is sent to your configured services.

### Manual Notifications
```ruby
begin
  risky_operation
rescue => e
  RailsErrorNotifier.notify(e, context: { user_id: current_user.id, path: request.path })
end
```

---

## 🔔 Example Notifications

### Slack
```
🚨 Rails Error Notifier
Message: undefined method `foo' for nil:NilClass
Context: {:user_id=>42, :path=>"/dashboard"}
Backtrace:
app/controllers/dashboard_controller.rb:12:in `index'
```

### Discord
```
⚡ Rails Error Notifier
Error: PG::ConnectionBad
Message: could not connect to server: Connection refused
Context: {:host=>"db.example.com", :env=>"production"}
```

---

## 🧪 Testing & Development

Clone the repository and install dependencies:

```bash
git clone https://github.com/mrmalvi/rails_error_notifier.git
cd rails_error_notifier
bundle install
```

Run the test suite:

```bash
bundle exec rspec
```

Start an interactive console to experiment:

```bash
bin/console
```

Build and install the gem locally:

```bash
bundle exec rake install
```

Release a new version (update `version.rb` first):

```bash
bundle exec rake release
```

This will:
- Create a Git tag for the version
- Push commits and tags
- Publish the `.gem` file to [rubygems.org](https://rubygems.org)

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repo
2. Create a new branch (`git checkout -b my-feature`)
3. Commit your changes (`git commit -am 'Add feature'`)
4. Push to the branch (`git push origin my-feature`)
5. Open a Pull Request

Bug reports and pull requests are welcome on GitHub:
👉 [https://github.com/mrmalvi/rails_error_notifier](https://github.com/mrmalvi/rails_error_notifier)

---

## 📜 License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
