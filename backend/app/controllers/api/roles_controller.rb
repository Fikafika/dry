class Api::RolesController < ::Api::BaseController

  concerning :Authorization do

    def skip_permissions?
      current_user_is_admin?
    end

    def check_permissions
      raise UneekPermission::UnauthorizedAction, "Forbidden"
    end

  end

end