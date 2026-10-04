class Api::Dynamic::Schema::Klass::Attribute::BaseController < Api::Dynamic::Schema::Klass::BaseController

  private

  def base_scope
    @base_scope ||= schema_attr.send(controller_class_name_to_association_name)
  end

  def schema_attr
    @schema_attr ||= find_by_id_or_name(schema_klass.attrs, params[:attribute_id], :underscore)
    @schema_attr
  end

  def where_exceptions
    super + ['attribute_id']
  end

  def controller_class_name_to_klass_name
    super.gsub('::Base', '')
  end
end
