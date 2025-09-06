module RailsErrorNotifier
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue => e
      RailsErrorNotifier.notify(e, context: { rack_env: env["PATH_INFO"] })
      raise
    end
  end
end
