class Api::Dynamic::Schema::Klass::AttributesController < Api::Dynamic::Schema::Klass::BaseController
  include RecomputeFormula

  before_action :store_normalizations, only: [:update]
  after_action :normalize_all, if: :normalization_changed?, only: [:update]

  private

  def base_scope
    @base_scope ||= schema_klass.attrs
  end

  def store_normalizations
    find_element
    @normalization_types_and_options = @element.normalizations.map {|n| [n.type, n.options]}
  end

  def normalize_all
    @element.try(:normalize_all_records_asynchronously)
  end

  def normalization_changed?
    new_normalization_types_and_options = @element.normalizations.map {|n| [n.type, n.options]}
    new_normalization_types_and_options != @normalization_types_and_options
  end

  def unpermitted_element_params_for_create
    {column: nil}
  end

  def unpermitted_element_params_for_update
    super.merge(
      klass_id: nil,
      baseklass_id: nil,
      column: nil,
      index: nil,
      type: nil,
    )
  end
end
