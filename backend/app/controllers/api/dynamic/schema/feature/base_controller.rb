class Api::Dynamic::Schema::Feature::BaseController < Api::Dynamic::Schema::BaseController

  def schema_feature
    @schema_feature ||= find_by_id_or_name(schema.features, params[:feature_id], :modulify_permalink)
  end

  def controller_class_name_to_klass_name
    super.gsub('::Feature::', '::')
  end

end
