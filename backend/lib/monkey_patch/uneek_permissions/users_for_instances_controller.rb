# frozen_string_literal: true

ActiveSupport.on_load(:uneek_permission_users_for_instances_controller) do

  concerning :Authentification do
    included do
      before_action :authenticate_user!
    end
  end

  concerning :Authorization do
    included do
      before_action :check_permissions
    end

    def check_permissions
      render json: { message: "You can not access this rule" }, status: :unauthorized unless current_user.admin?
    end
  end

end