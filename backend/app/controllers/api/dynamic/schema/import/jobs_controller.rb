class Api::Dynamic::Schema::Import::JobsController < Api::Dynamic::Schema::Import::BaseController

  def process(*args)
    return super unless args.length == 0 # this method already exists in ActionController
    find_element
    @element.process
    render :json => job
  end

  private

  def scope
    @scope ||= import_setting.jobs
  end

  def import_setting
    schema.import_settings.find(params[:import_setting_id])
  end

  def job
    scope.find(params[:id])
  end

end