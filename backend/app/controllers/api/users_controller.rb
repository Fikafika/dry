class Api::UsersController < ::Api::BaseController

  def current
    if warden.authenticated?(scope: :user)
      render json: current_user.as_deep_json(includes_for_current_user), status: :ok
    else
      head :not_found
    end
  end

  private

  def includes_for_current_user
    {
      secure: false,
      only: [
        :id,
        :last_name,
        :first_name,
        :email,
        :login,
        :super_admin,
        :language,
        :has_photo,
      ],
      include: {
        photo_url: {},
        communities: {
          only: [
            :id,
            :name,
            :permalink,
            :has_logo,
            :theme_id,
            :schema_id,
            :uneek_sso_uuid,
          ],
          include: {
            logo_url: {},
            theme: {},
            schema_name: {},
          },
        },
        memberships: {
          only: [
            :id,
            :community_id,
            :admin,
            :status,
          ]
        },
        roles: {
          only: [
            :name,
            :human_name,
            :default,
            :admin,
          ],
          include: {
            community: {
              only: [
                :id,
                :name,
                :permalink,
                :has_logo,
                :theme_id,
                :schema_id,
              ]
            }
          }
        },
        permissions_for_features: {},
      }
    }
  end

  concerning :Authentication do

    def authenticate_before_find_element?
      action_name != 'current'
    end

    def authenticate_after_find_element?
      action_name != 'current' # TODO check
    end

  end

  concerning :Authorization do

    def skip_permissions?
      action_name == 'current' || current_user_is_admin?
    end

    def check_permissions
      raise UneekPermission::UnauthorizedAction, 'Forbidden'
    end

  end

end
