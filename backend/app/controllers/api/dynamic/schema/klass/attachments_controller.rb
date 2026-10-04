class Api::Dynamic::Schema::Klass::AttachmentsController < Api::Dynamic::Schema::Klass::BaseController

  private

  def element_params
    result = super
    result[:owner_klass_id] ||= owner_klass_id if owner_klass_id
    return result
  end

  def owner_klass_id
    schema_klass&.id
  end

  def unpermitted_element_params_for_update
    super.merge(
      owner_klass_id: nil,
      baseklass_id: nil,
    )
  end

end
