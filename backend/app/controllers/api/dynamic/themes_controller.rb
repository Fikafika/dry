class Api::Dynamic::ThemesController < Api::Dynamic::BaseController

  private

  def find_element
    @element = find_by_id_or_name(scope, params[:id])
  end

  def base_scope
    schema_id ? schema.send(controller_class_name_to_association_name) : super
  end

  def schema
    @schema ||= find_by_id_or_name(Dynamic::Schema, schema_id, :classify_permalink)
    @schema
  end

  def schema_id
    params.dig(element_params_key, :schema_id) || params.dig(:where, :schema_id) || params[:schema_id]
  end

  def where_exceptions
    super + ['schema_id']
  end

  concerning :Authentication do

    def skip_verify_authenticity_token?
      true
    end

    def authenticate_before_find_element?
      !action_name.in?(['index', 'show'])
    end

    def authenticate_after_find_element?
      !action_name.in?(['index', 'show'])
    end

  end

  concerning :Authorization do

    def skip_permissions?
      current_user_is_admin?
    end

    def check_permissions
      unless action_name.in?(['index', 'show']) || @element.nil?
        raise UneekPermission::UnauthorizedAction, "You can not access theme #{@element.name}"
      end
    end

  end

end
