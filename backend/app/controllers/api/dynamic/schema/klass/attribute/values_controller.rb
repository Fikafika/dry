class Api::Dynamic::Schema::Klass::Attribute::ValuesController < Api::Dynamic::Schema::Klass::Attribute::BaseController

  private

  def scope
    @scope ||= schema_attr.values
  end

  def controller_class_name_to_klass_name
    'Dynamic::Schema::Attribute::Enum::Value'
  end
end
