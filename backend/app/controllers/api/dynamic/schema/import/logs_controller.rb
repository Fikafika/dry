class Api::Dynamic::Schema::Import::LogsController < Api::Dynamic::Schema::Import::BaseController

  def base_scope
    job.logs
  end

  def import_setting
    schema.import_settings.find(params[:import_setting_id])
  end

  def job
    import_setting.jobs.find(params[:job_id])
  end

end