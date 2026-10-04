# frozen_string_literal: true

module MonkeyPatch
  module SessionChannel

    def self.broadcast_session_id_changed(env, old_session_id, new_session_id, **options)
      env['broadcast_session_channel'] ||= {}
      env['broadcast_session_channel'][:session_id_changed] = {
        old_session_id: old_session_id,
        new_session_id: new_session_id,
      }.merge(options)
      env
    end

    def self.broadcast_current_user(env, current_user, **options)
      env['broadcast_session_channel'] ||= {}
      env['broadcast_session_channel'][:current_user] = {
        attributes: current_user&.as_json(only: [:id, :uneek_sso_uuid]),
      }.merge(options)
      env
    end

    def self.broadcast_destroyed(env)
      env['broadcast_session_channel'] ||= {}
      env['broadcast_session_channel'][:destroyed] = {}
      env
    end

    def self.broadcast!(env, session_id)
      return unless env['broadcast_session_channel']
      if env['broadcast_session_channel'][:session_id_changed]
        broadcast_session_id = env['broadcast_session_channel'][:session_id_changed][:old_session_id]
      else
        broadcast_session_id = session_id
      end
      ::SessionChannel.broadcast_to(broadcast_session_id, env['broadcast_session_channel'])
    end

  end
end
