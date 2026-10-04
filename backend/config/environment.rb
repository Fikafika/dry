# Load the Rails application.
require_relative "application"

Rails.application.config.action_cable.allowed_request_origins = [ nil ]

# Initialize the Rails application.
Rails.application.initialize!
