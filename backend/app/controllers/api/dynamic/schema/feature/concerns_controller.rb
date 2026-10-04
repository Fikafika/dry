class Api::Dynamic::Schema::Feature::ConcernsController < Api::Dynamic::Schema::Feature::BaseController

  private

  def base_scope
    @base_scope ||= schema_feature.concerns
  end

  def where_exceptions
    super + ['feature_id']
  end

  def element_params
    result = super
    result.delete(:concern_template)
    return result
  end
end