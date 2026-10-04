class Api::Dynamic::Schema::FeaturesController < Api::Dynamic::Schema::BaseController

  def find_element
    @element = find_by_id_or_name(scope, params[:id], :modulify_permalink)
  end

end
