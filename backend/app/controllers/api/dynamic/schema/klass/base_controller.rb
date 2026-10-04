class Api::Dynamic::Schema::Klass::BaseController < Api::Dynamic::Schema::BaseController

  around_action :enable_notification

  private

  def find_element
    @element = find_by_id_or_name(scope, params[:id], :underscore)
  end

  def base_scope
    @base_scope ||= schema_klass.send(controller_class_name_to_association_name)
  end

  def schema_klass
    @schema_klass ||= find_by_id_or_name(schema.klasses, params[:klass_id], :classify)
  end

  def where_exceptions
    super + ['klass_id']
  end

  def controller_class_name_to_klass_name
    "#{super.gsub('::Klass::', '::')}::Base"
  end

  def unpermitted_element_params_for_update
    super.merge(
      schema_id: nil,
    )
  end

  concern :RecomputeFormula do

    def recompute_formula
      find_element
      result = @element.try(:recompute_formula)
      head :ok
    end

  end
end
