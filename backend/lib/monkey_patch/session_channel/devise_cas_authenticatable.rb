# frozen_string_literal: true

require 'devise_cas_authenticatable/cas_session_ticket'

module MonkeyPatch
  module SessionChannel
    module CasSessionTicket; extend ActiveSupport::Concern

      included do
        after_destroy_commit :broadcast_destroyed
      end

      private

      def broadcast_destroyed
        SessionChannel.broadcast!(SessionChannel.broadcast_destroyed({}), self.session_id)
      end

    end
  end
end

::DeviseCasAuthenticatable::CasSessionTicket.include(MonkeyPatch::SessionChannel::CasSessionTicket)
