ActiveSupport.on_load(:dynamic_form_submission) do
  class Dynamic::Form::Submission
    include HyperResourceBroadcastUpdate

    def broadcast_update?
      state_previously_changed? && previous_changes['state']&.first == 'delayed'
    end
  end
end
