# frozen_string_literal: true

UneekSsoClient.configure do |config|
  # Configuration of the API
  # You can add as many servers as you want.
  config.server 'kosmopolead', {
    :protocol => ENV['UNEEK_SSO_PROTOCOL'],
    :host => ENV['UNEEK_SSO_HOST'],
    :username => ENV['UNEEK_SSO_USERNAME'],
    :password => ENV['UNEEK_SSO_PASSWORD'],
  }

  # Configuration of SSL for HTTPClient
  # config.ssl_config = {
  #   :verify_mode => OpenSSL::SSL::VERIFY_NONE,
  # }

  # Logger file.
  config.logger = Logger.new(File.join(Rails.root, 'log', "uneek_sso_client_#{Rails.env}.log"))

  # Interval between each request to the SSO server to prevent timeout and send tracked informations.
  # config.timeout_touch_interval = 1.minute.to_i

  # Parameters to be filtered in logs.
  # Note that a nil value will filter ALL parameters.
  # config.filtered_parameters = [:password, :auth_token]

  # Adds temporary token params to url when redirecting to CAS server.
  # config.temporary_token_in_params = true

  # The URL options to build the URL present in the mail sent when a temporary token is created without a resource. Default is nil.
  # config.temporary_token_default_url_options = { controller: 'devise/cas_sessions', action: 'new' }

  # Parent class of UneekSsoClient::Mailer.
  # config.parent_mailer = 'ApplicationMailer'

  # Time to wait before considering that an API request to the SSO server has failed.
  # config.api_timeout = 1.minute.to_i

  # Max number of retries when trying to get an authentication token in API.
  # 1 should be enough.
  # config.max_api_reconnect_tries = 1

  # Max number of retries when syncing a resource during an update.
  # If the resource is constantly updated on the server, the client will not be able to push its changes.
  # Note that a nil value may cause an infinite loop.
  # config.max_api_sync_update_tries = 10

  # Time to wait before considering that a cas sessions API request to the SSO server with has failed.
  # config.api_cas_session_timeout = 1.second.to_i

  # Enables automatic synchronization to the servers.
  config.sync_enabled = !Rails.env.test?

  # Disables some synchronizations actions among :create, :update, :destroy, :client_create and :client_destroy.
  # config.sync_disabled_actions = Set.new([:destroy, :client_destroy])

  # Classes to sync in rake task uneek_sso_client:sync_all.
  # Default is empty array.
  config.sync_classes = ['Community', 'Tool', 'Role', 'RoleContextField', 'User', 'Membership', 'UserRole', 'UserRole::DomainContext']

  # Associations to sync in rake task uneek_sso_client:sync_all.
  # Default is empty hash.
  # config.sync_children_associations = { 'User' => ['temporary_tokens'] }

  # Associations to sync in rake task uneek_sso_client:sync_all.
  # Default is empty hash.
  # config.sync_children_associations = { 'User' => ['temporary_tokens'] }

  # Parent class of api sync controllers for double synchronization.
  # config.sync_parent_controller = 'ActionController::API'

  # The username and password of sync controllers for double synchronization of HTTP Basic authentication
  config.sync_controller_username = ENV['UNEEK_SSO_SYNC_CONTROLLER_USERNAME']
  config.sync_controller_password = ENV['UNEEK_SSO_SYNC_CONTROLLER_PASSWORD']

  # On successful CAS requests to the SSO server, returns a "created" status and renders a template for XHR requests.
  # Possible values are :
  #   - :render: render the HTML template in app/views/devise/cas_sessions/service_xhr.html.erb
  #   - :head: render an empty template
  #   - nil: disable
  config.created_status_on_service_xhr_request = :head

  # The name of the backjob queue
  # config.backjob_queue = 'low'
end
