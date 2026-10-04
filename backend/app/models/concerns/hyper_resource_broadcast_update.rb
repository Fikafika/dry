module HyperResourceBroadcastUpdate; extend ActiveSupport::Concern
  included do
    after_touch :broadcast_update, if: :broadcast_update?
    after_commit :broadcast_update, if: :broadcast_update?
  end

  def broadcast_user_id # must be redefined if the record must be broadcasted to a specific user
    nil
  end

  private

  def broadcast_update
    ::HyperResourceChannel.broadcast(self)
  end

  def broadcast_update? # can be redefined
    true
  end

end
