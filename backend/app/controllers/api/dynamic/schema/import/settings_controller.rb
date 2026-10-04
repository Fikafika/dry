class Api::Dynamic::Schema::Import::SettingsController < Api::Dynamic::Schema::Import::BaseController

  before_action(only: [
    :duplicate,
    :run_cron,
    :find_cron,
    :disable_cron,
    :enable_cron,
    :show_status_cron,
    :enqueue_cron,
    :destroy_cron
  ]) { find_element }

  def process_all(*args)
    return super if args.length > 0
    find_element
    job = @element.jobs.init_jobs.where(state: :pending).last
    job = @element.create_init_job unless job
    job.process
    render :json => job
  end

  def duplicate
    element = @element.duplicate!
    render json: to_json(element), status: :created
  end

  def run_cron
    job = @element.run_cron
    render :json => job
  end

  def find_cron
    job = @element.find_cron
    render :json => job
  end

  def disable_cron
    @element.disable_cron
    render :json => @element.find_cron
  end

  def enable_cron
    @element.enable_cron
    render :json => @element.find_cron
  end

  def show_status_cron
    @element.show_status_cron
    render :json => @element.find_cron
  end

  def enqueue_cron
    @element.enqueue_cron
    render :json => @element.find_cron
  end

  def destroy_cron
    @element.destroy_cron
    render :json => @element.find_cron
  end

  def allowed_scopes
    super + ['for_klass']
  end

  private

  def controller_class_name_to_klass_name
    'Dynamic::Import::Setting'
  end

  def base_scope
    @base_scope ||= schema.import_settings
  end

  def element_params
    result = super
    result[:actor] = current_user
    result[:schema_id] = schema.id
    return result
  end

  def check_permissions
    case action_name
    when 'find_cron' 'show_status_cron'
      raise UneekPermission::UnauthorizedAction, "You are not allowed to read this object" unless @element.can_be_read_by?(current_user)
    when 'process_all' 'run_cron' 'disable_cron' 'enable_cron' 'enqueue_cron' 'destroy_cron'
      raise UneekPermission::UnauthorizedAction, "You are not allowed to update this object" unless @element.can_be_updated_by?(current_user)
    when 'duplicate'
      raise UneekPermission::UnauthorizedAction, "You are not allowed to create this object" unless @element.can_be_created_by?(current_user)
    else
      super
    end
  end

end
