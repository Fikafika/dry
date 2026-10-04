# frozen_string_literal: true

class SessionChannel < ApplicationCable::Channel

  delegate :session, to: :connection

  def subscribed
    stream_for session_id
  end

end
