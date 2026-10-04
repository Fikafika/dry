class Api::Dynamic::Schema::Klass::ValidationsController < Api::Dynamic::Schema::Klass::BaseController

  def scope
    return super.where(attr_id: schema_klass_attr.id) if attr_id_param
    super
  end

  def element_params
    r = super.except(:attr_type)
    r.merge!(attr: schema_klass_attr) if attr_id_param
    return r
  end

  def where_exceptions
    super + ['attr_id']
  end

  def attr_id_param
    return params[:validation][:attr_id] if params[:validation]
    params[:where][:attr_id] if params[:where]
  end

  def schema_klass_attr
    @schema_klass_attr ||= find_by_id_or_name(schema_klass.attrs, attr_id_param)
  end

  def unpermitted_element_params_for_update
    super.merge(
      klass_id: nil,
    )
  end
end
