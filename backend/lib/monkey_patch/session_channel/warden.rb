# frozen_string_literal: true

require 'monkey_patch/session_channel/base'

::Warden::Manager.after_set_user do |record, warden, options|
  next unless options[:scope] == :user
  next if options[:event] == :fetch

  ::MonkeyPatch::SessionChannel.broadcast_current_user(warden.env, record)
end

::Warden::Manager.before_logout do |record, warden, options|
  next unless options[:scope] == :user

  ::MonkeyPatch::SessionChannel.broadcast_current_user(warden.env, nil, pending_uneek_sso_sign_out: !warden.env[::UneekSsoClient::ENV_LOGOUT])
end
