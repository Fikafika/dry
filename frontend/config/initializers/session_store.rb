Rails.application.config.action_dispatch.cookies_same_site_protection = :none
Rails.application.config.session_store :active_record_store, :key => '_dynamo_session', :secure => (ENV['DYNAMO_PROTOCOL'] == 'https')
