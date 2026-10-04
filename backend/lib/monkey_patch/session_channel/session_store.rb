# frozen_string_literal: true

require 'action_dispatch/session/active_record_store'

module MonkeyPatch
  module SessionChannel
    module ActiveRecordStore

      def delete_session(request, session_id, options)
        new_sid = super
        if new_sid
          request.session['old_session_id'] = session_id
        else
          SessionChannel.broadcast_destroyed
        end
        SessionChannel.broadcast!(request.env, session_id)
        new_sid
      end

    end
  end
end

::ActionDispatch::Session::ActiveRecordStore.prepend(::MonkeyPatch::SessionChannel::ActiveRecordStore)
