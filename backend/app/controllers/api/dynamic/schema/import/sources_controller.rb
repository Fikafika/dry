class Api::Dynamic::Schema::Import::SourcesController < Api::Dynamic::Schema::Import::BaseController

  def scope
    @scope ||= import_setting.sources
  end

  def import_setting
    schema.import_settings.find(params[:import_setting_id])
  end

  def source
    scope.find(params[:id])
  end

end
