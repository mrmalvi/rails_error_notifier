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
gem 'rails_error_notifier'
gem 'rails_error_notifier', git: 'https://github.com/mrmalvi/rails_error_notifier.git'
