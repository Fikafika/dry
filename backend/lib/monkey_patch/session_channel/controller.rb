# frozen_string_literal: true

module MonkeyPatch
  module SessionChannel
    module Controller; extend ActiveSupport::Concern

      included do
        after_action :trigger_broadcast_session_channel
      end

      private

      def trigger_broadcast_session_channel
        if session['old_session_id']
          SessionChannel.broadcast_session_id_changed(request.env, session.delete('old_session_id'), session.id)
        end
        SessionChannel.broadcast!(request.env, session.id)
      end

    end
  end
end
