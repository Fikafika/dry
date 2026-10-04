class Api::Dynamic::Schema::Klass::AssociationsController < Api::Dynamic::Schema::Klass::BaseController
  include RecomputeFormula

  private

  def element_params
    result = super
    result[:owner_klass_id] ||= owner_klass_id if owner_klass_id
    return result
  end

  def owner_klass_id
    schema_klass&.id
  end

  def where_params
    return nillify_target_klass_id(super)
  end

  def where_not_params
    return nillify_target_klass_id(super)
  end

  def nillify_target_klass_id(params_to_nillify)
    if params_to_nillify[:target_klass_id].is_a?(Array)
      params_to_nillify[:target_klass_id]&.each_with_index do |id, i|
        params_to_nillify[:target_klass_id][i] = nil if id&.empty?
      end
    end
    return params_to_nillify
  end

  def unpermitted_element_params_for_update
    super.merge(
      owner_klass_id: nil,
      baseklass_id: nil,
    )
  end

end
