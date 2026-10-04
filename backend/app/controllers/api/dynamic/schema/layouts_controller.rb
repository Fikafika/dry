class Api::Dynamic::Schema::LayoutsController < Api::Dynamic::Schema::BaseController

  private

  def base_scope
    if params[:klass_id]
      super.where(klass_name: schema_klass_name)
    else
      super
    end
  end

  def controller_class_name_to_klass_name
    "#{super.gsub('::Schema::', '::')}::Base"
  end

  def element_params
    result = super
    result.delete(:klass_id)
    return result
  end

  def schema_klass
    @schema_klass ||= find_by_id_or_name(schema.klasses, params[:klass_id], :classify)
  end

  def schema_klass_name
    "D::#{schema.name}::#{schema_klass.name}"
  end

  def find_element
    @element = scope.find(params[:id])
  end

  def where_exceptions
    super + ['klass_id']
  end

  def allowed_scopes
    [
      'with_action',
      'with_actions',
      'for_menu_item',
      'with_deleted',
    ]
  end

  concerning :Authorization do

    def skip_permissions?
      true
    end

  end

end
