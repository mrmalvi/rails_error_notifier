# 🚨 Rails Error Notifier – Ruby Gem for Error Monitoring in Rails

[![Gem Version](https://badge.fury.io/rb/rails_error_notifier.svg)](https://rubygems.org/gems/rails_error_notifier)
[![Build Status](https://github.com/mrmalvi/rails_error_notifier/actions/workflows/ci.yml/badge.svg)](https://github.com/mrmalvi/rails_error_notifier/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Rails Error Notifier** is an open-source **Ruby gem** for **Rails 6+ applications** that automatically captures unhandled exceptions and sends instant notifications.
It integrates with **Slack**, **Discord**, **Email**, and **WhatsApp (Twilio)** so your team is immediately alerted to production errors.

👉 [RubyGems page](https://rubygems.org/gems/rails_error_notifier) |
👉 [Source code on GitHub](https://github.com/mrmalvi/rails_error_notifier)

---

## ✨ Features
- 🔥 Automatic error capturing in Rails via Rack middleware.
- 📩 Send error notifications to:
  - Slack
  - Discord
  - Email
  - WhatsApp (via Twilio API)
- ⚙️ Easy setup with Rails generator.
- 📝 Add custom context (current user, request path, environment).
- 🛡️ Safe failover (won’t crash if webhooks or configs are missing).
- 🧩 Works seamlessly with **Rails 6, Rails 7, Ruby 2.0+**.

---

## 📦 Installation

Add this line to your `Gemfile`:

```ruby
gem 'rails_error_notifier', git: 'https://github.com/mrmalvi/rails_error_notifier.git'
```

Install the gem:

```bash
bundle install
```

Or install manually:

```bash
gem install rails_error_notifier
```

---

## ⚙️ Configuration

Generate initializer:

```bash
bin/rails generate rails_error_notifier:install
```

This creates `config/initializers/rails_error_notifier.rb`:

```ruby
RailsErrorNotifier.configure do |config|
  # Slack + Discord
  config.slack_webhook   = ENV["SLACK_WEBHOOK_URL"] # "https://hooks.slack.com/services/T000/B000/XXXX"
  config.discord_webhook = ENV["DISCORD_WEBHOOK_URL"] # "https://discord.com/api/webhooks/1234567890/abcXYZ"

  # Email
  config.error_email_to   = ENV["ERROR_EMAIL_TO"]   # e.g. "dev-team@example.com"
  config.error_email_from = ENV["ERROR_EMAIL_FROM"] # e.g. "notifier@example.com"

  # WhatsApp (via Twilio)
  config.twilio_sid   = ENV["TWILIO_SID"] #"AC1234567890abcdef1234567890abcd"
  config.twilio_token = ENV["TWILIO_TOKEN"] #"your_auth_token_here"
  config.twilio_from  = ENV["TWILIO_FROM"] #"+14155552671"
  config.twilio_to    = ENV["TWILIO_TO"] # "whatsapp:+919876543210"

  # Enable in production only
  config.enabled = !Rails.env.development? && !Rails.env.test?
end
```

---

## 🚀 Usage

### Automatic Error Notifications
Rails middleware will automatically send alerts for any unhandled exception.

### Manual Error Notifications
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
```

### Discord
```
⚡ Rails Error Notifier
Error: PG::ConnectionBad
Message: could not connect to server: Connection refused
Context: {:host=>"db.example.com", :env=>"production"}
```

---

## 🧪 Development & Testing

Clone and setup:

```bash
git clone https://github.com/mrmalvi/rails_error_notifier.git
cd rails_error_notifier
bundle install
```

Run specs:

```bash
bundle exec rspec
```

Build gem locally:

```bash
bundle exec rake install
```

Release a version:

```bash
bundle exec rake release
```

---

## 🤝 Contributing

Contributions, bug reports, and pull requests are welcome!
See [issues](https://github.com/mrmalvi/rails_error_notifier/issues).

---

## 📜 License

Released under the [MIT License](LICENSE).

---

### 📈 SEO Keywords
*Rails error notifier gem, Ruby gem for error logging, Slack error notification Rails, Discord error notification Rails, Rails exception tracker, Rails monitoring gem, Ruby on Rails error reporting.*
