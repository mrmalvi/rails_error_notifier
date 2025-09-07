require "rails_error_notifier/configuration"
require "rails_error_notifier/notifier"
require "rails_error_notifier/error_notifier_mailer"
require "rails_error_notifier/middleware"
require "rails_error_notifier/railtie" if defined?(Rails::Railtie)

module RailsErrorNotifier
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.notify(exception, context: {})
    Notifier.new(exception, context).deliver
  end
end
