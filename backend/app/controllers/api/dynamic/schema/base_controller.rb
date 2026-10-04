class Api::Dynamic::Schema::BaseController < Api::Dynamic::BaseController

  around_action :sidekiq_throttle_admin

  private

  def find_element
    @element = find_by_id_or_name(scope, params[:id], :classify)
  end

  def base_scope
    @base_scope ||= schema.send(controller_class_name_to_association_name)
  end

  def schema
    @schema ||= find_by_id_or_name(Dynamic::Schema, params[:schema_id], :classify_permalink)
  end

  def where_exceptions
    super + ['schema_id']
  end

  def cache_params
    super.merge(schema_updated_at: schema&.updated_at)
  end

  concerning :Authorization do

    def check_permissions
      if klass_is_controlled?
        super
      else
        check_permissions_for_public_schema_actions
      end
    end

    def check_permissions_for_public_schema_actions
      unless action_name.in?(public_schema_actions) || @element.nil?
        raise UneekPermission::UnauthorizedAction, "You can not access #{@element.class.name} #{@element.name}"
      end
    end

    def public_schema_actions
      ['index', 'show']
    end

  end

  concerning :Cache do

    def manifest_scope
      manifest_scope_for_schema_name(params[:schema_id]&.classify_permalink)
    end

  end

end
