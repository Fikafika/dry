class Api::Dynamic::Schema::Layout::ElementsController < Api::Dynamic::Schema::BaseController

  private

  def base_scope
    if params.require(:layout_id) == 'any'
      klass
    else
      layout.elements
    end
  end

  def klass
    Dynamic::Layout::Element
  end

  def layout
    @layout ||= Dynamic::Layout.where(klass_name: schema_klass_name).find(params.require(:layout_id))
  end

  def element_params
    result = super
    result.delete(:klass_id)
    return result
  end

  def schema_klass
    @schema_klass ||= find_by_id_or_name(schema.klasses, params.require(:klass_id), :classify)
  end

  def schema_klass_name
    "D::#{schema.name}::#{schema_klass.name}"
  end

  def where_exceptions
    super + ['klass_id']
  end

end
