# frozen_string_literal: true

ActiveSupport.on_load(:uneek_permission_rules_controller) do
  concerning :Authentification do
    included do
      prepend_before_action :authenticate_user!
    end
  end

  concerning :Authorization do
    included do
      before_action :check_permissions
      before_action :check_receiver, only: [:create, :update]
    end

    def check_permissions
      head :unauthorized unless current_user&.admin?(@schema&.id)
    end

    def check_receiver
      render json: { message: "You can not edit this rule" }, status: :unauthorized if receiver_admin?(@receiver)
    end

    def receiver_admin?(receiver)
      if receiver.is_a?(::User)
        receiver.admin?(@schema&.id)
      else
        receiver.try(:admin?) == true
      end
    end

    def can_destroy_rule?(rule)
      !!receiver_admin?(rule.receiver)
    end
  end

end
