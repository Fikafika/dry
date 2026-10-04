class SilenceRequest
  def initialize(app, path:)
    @app, @path = app, path
  end

  def call(env)
    if env["PATH_INFO"] == @path
      Rails.logger.silence { @app.call(env) }
    else
      @app.call(env)
    end
  end
end

Rails.application.config.middleware.insert_before Rails::Rack::Logger, SilenceRequest, path: "#{ENV['APP_PATH_PREFIX']}/up"
