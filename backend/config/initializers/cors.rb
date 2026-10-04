# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors


allowed_origins = ENV['DYNAMO_BACKEND_ALLOWED_ORIGINS']&.split(' ') || []

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # allow do
  #   origins 'example.com'

  #   resource '*',
  #     headers: :any,
  #     methods: [:get, :post, :put, :patch, :delete, :options, :head]
  # end

  allow do
    origins Proc.new{|source, env| source == 'null' || source == "#{ENV['DYNAMO_PROTOCOL']}://#{ENV['DYNAMO_HOST']}"}

    # resource '/api/users/sign_in', headers: :any, methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day # if you want to handle connections TO your application from another application
    resource '/api/users/service', headers: :any, methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day
    resource '/api/users/service_xhr', headers: :any, expose: ['X-CSRF-Token'], methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day
  end

  allow do
    origins Proc.new{|source, env| source == 'null' || allowed_origins.include?(source)}
    resource '/api/d/*', headers: :any, methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day
    resource '/api/dynamic/*', headers: :any, methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day
    resource '/api/lsp/d/*', headers: :any, methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day
    resource '/api/cd83/*', headers: :any, methods: [:get, :options], credentials: true, max_age: Rails.env.development? ? 10.seconds : 1.day
  end
end
