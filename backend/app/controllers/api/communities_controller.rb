class Api::CommunitiesController < ::Api::BaseController

  private

  def find_element
    @element = find_by_id_or_name(scope, params[:id], :classify)
  end

  concerning :Cache do

    def manifest_scope
      UneekPermission::Manifest.joins(:community).where(community: {id: params[:id]})
    end

  end

end
