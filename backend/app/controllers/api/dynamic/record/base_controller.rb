require 'dynamic/datatable/adapter'

class Api::Dynamic::Record::BaseController < Api::Dynamic::BaseController
  include LoadSchema
  include EnableWaitForCompletedJobs

  around_action :sidekiq_throttle_user
  around_action :enable_notification, if: :reserved?

  skip_verify_authenticity_token_for_jwt # Allow external service user using only jwt

  prepend_around_action :load_schema

  around_action :enable_wait_for_completed_jobs, only: [:create, :update, :update_all, :destroy, :destroy_all, :import, :update_positions]
  around_action :enable_with_dependencies_computed_later, only: [:update_all, :destroy_all, :import, :update_positions]

  before_action :perform_async, only: [:update_all, :destroy_all], if: -> { params[:async] }

  before_action :render_vcard, only: [:show], if: -> { params[:format].in?(['vcf', 'vcard']) }

  ADAPTERS = {
    'datatable' => Dynamic::Datatable::Adapter,
    'dashboard' => Dynamic::Dashboard::Adapter,
    'select2' => self::Select2,
  }.freeze

  def update_all # redefined in order to call update(:all) instead of update_all() for run callbacks
    update_method = params[:differential] ? :differential_update : :update
    s = scope_for_permissions(scope, action_name)
    render json: s.send(update_method, :all, element_params), status: :ok
  end

  def import
    array_of_attributes = params.require(element_params_key.pluralize)
    array_of_attributes = Array(array_of_attributes)
    array_of_attributes = array_of_attributes.map{|e| e.permit!.to_h }

    if array_of_attributes.any?
      options = params[:options]&.permit&.to_h || {}
      unless options.has_key?(:validate)
        options[:validate] = true
        options[:track_validation_failures] = true
      end
      columns = array_of_attributes.first.keys.keep_if { |k| !k.end_with?("_id") }.map(&:to_sym)
      options[:on_duplicate_key_update] ||= {conflict_target: [:id], columns: (columns - [:id])}

      import_result = klass.import(array_of_attributes, **options)

      result = {}
      result[:ids] = import_result.ids
      result[:errors] = {}
      import_result.failed_instances.each do |fi|
        result[:errors][fi.first] = fi.last&.errors&.details
      end
    else
      result = {ids: [], errors: {}}
    end

    render json: result, status: :ok
  end

  def update_positions
    p = params
    relation = scope
    attr = p[:attr].to_s
    dir = p[:direction].to_s
    source_value = p[:source]
    target_value = p[:target]
    moved = relation.find(p[:source_id])
    target = p[:target_id].present? ? relation.find(p[:target_id]) : nil

    position_klass = moved.class.module_parent::R::Position

    if p[:source_id] == p[:target_id]
      existing = position_klass.find_by_record(
        moved,
        attr,
        target_value
      )

      render json: {
        new_position: existing&.value,
        success: true
      }, status: :ok

      return
    end

    new_position = nil

    ActiveRecord::Base.transaction do
      position_klass.create_missing(
        attr,
        source_value,
        target_value,
        moved,
        target,
        relation
      )

      if source_value != target_value
        relation.where(id: moved.id).update(
          attr => target_value,
          updated_at: Time.current
        )

        new_position = position_klass.move_across_columns(
          attr,
          source_value,
          target_value,
          moved,
          target,
          dir
        )
      else
        new_position = position_klass.move_within_column(
          attr,
          target_value,
          moved,
          target,
          dir
        )
      end
    end

    render json: {
      new_position: new_position,
      success: true
    }, status: :ok
  end


  def data
    result = {}
    user = User.current
    threads = []
    params.each do |adapter_name, adapter_params|
      adapter = ADAPTERS[adapter_name]
      next unless adapter
      threads << Thread.new do
        Rails.application.executor.wrap do
          begin
            User.current = user # transfert from main thread
            result[adapter_name] = adapter.new(klass, adapter_params).as_json
          rescue StandardError => e
            result[adapter_name] = { error: e.message }
            Rails.logger.error e.message + " : " + e.backtrace.join("\n")
          end
        end
      end
    end
    threads.each { |t| t.join }
    render json: result, status: :ok
  end

  def datatable
    render json: ADAPTERS['datatable'].new(klass, params), status: :ok
  end

  def dashboard
    render json: ADAPTERS['dashboard'].new(klass, params), status: :ok
  end

  private

  def reserved?
    params[:klass_name]&.start_with?('r__')
  end

  def klass
    @klass ||= compute_klass(params[:klass_name])
  end

  def base_scopes
    klasses
  end

  def klasses
    return @klasses if @klasses
    if params[:klass_name]
      begin
        @klasses = [klass]
      rescue NameError => e
        Rails.logger.error e.message + " : " + e.backtrace.join("\n")
        @klasses = []
      end
    elsif params[:klass_names].present?
      @klasses = []
      params[:klass_names].each do |k|
        begin
          @klasses << compute_klass(k)
        rescue NameError => e
          Rails.logger.error e.message + " : " + e.backtrace.join("\n")
        end
      end
    else
      @klasses = []
    end
    return @klasses
  end

  def compute_klass(klass_name)
    return unless klass_name
    if klass_name.start_with?('D::')
      return klass_name.constantize
    elsif klass_name =~ /^[a-z]/ # start with downcase
      result = "D::#{schema_name}".constantize.const_get_by_route_key(klass_name)
    else
      result = "D::#{schema_name}::#{klass_name}".constantize
    end
    return result
  end

  def schema_name
    @schema_name ||= params[:schema_name].classify_permalink
  end

  def allowed_scopes
    ['where_filters', 'where_query', 'join_positions']
  end

  def where_exceptions
    super + ['schema_name'] + (!klass.abstract_class? && klass.has_attribute?('klass_name') ? [] : ['klass_name'])
  end

  def perform_async
    worker_klass = ::Dynamic::Record.const_get("#{action_name.classify}Worker")
    notification = create_notification
    perform_params = {
      klass_name: klass.name,
      params: params.permit!.to_h,
      user_id: User.current.id,
      notification: notification,
    }.deep_stringify_keys
    worker_klass.perform_async(perform_params)
    render json: notification, status: :accepted
  end

  def create_notification
    notification_klass = klass.module_parent::R::Notification
    return notification_klass&.create!(
      user_id: User.current.id,
      klass_name: "Bulk::#{action_name.classify}",
      total: scope.count,
      data: {klass_name: klass.name},
      can_cancel: true,
    )
  end

  def render_vcard
    raise ActionController::UnknownFormat unless @element.is_a?(Dynamic::Vcard::Base)
    options = {
      rev: @element.updated_at,
      tz: Time.zone.tzinfo.name,
    }
    vcard = Dynamic::Vcard::Generator.new(@element, options).run

    name_attr = @element.class.name_attribute
    record_name = name_attr ? @element.send(name_attr) : @element.id
    send_data vcard, filename: "#{record_name}.vcf", type: 'text/x-vcard', status: :ok
  end

  class Select2
    include ::Select2::Elasticsearch
  end

  def enable_with_dependencies_computed_later
    ::ModelDependency.with_dependencies_computed_later do
      yield
    end
  end

  concerning :Cache do

    def cache_enabled?
      return reserved? && klass && reserved_cached[klass.name.split('::R::').last]&.call(params)
    end

    def reserved_cached
      {
        'Menu' => lambda {|_| true },
        'Query::Base' => lambda {|_| true },
      }
    end

    def cache_params
      super.merge(schema_updated_at: @schema&.updated_at)
    end

    def manifest_scope
      manifest_scope_for_schema_name(schema_name)
    end

  end

  concerning :Authentication do

    def skip_verify_authenticity_token?
      action_name.in?(['datatable', 'dashboard', 'data']) # because they are post for technical reason (too much parameters) but don't change server state
    end

    def authenticate_before_find_element?
      return false if requesting_show_vcard? # rendering vcard is public implying that all fields can be exported
      return false if action_name.in?(['index', 'show']) && klass&.include?(UneekPermission::ControlledKlass) && klass.can_be_read_by?(::UneekPermission::PredefinedReceiver::Public.instance)
      return true
    end

    def requesting_show_vcard?
      action_name == 'show' && params[:format].in?(['vcf', 'vcard'])
    end

    def requesting_select2?
      action_name == 'index' && params[:select2]
    end

  end

  concerning :Authorization do

    def check_permissions
      if requesting_show_vcard?
        raise UneekPermission::UnauthorizedAction, "You are not allowed to read this vcard" unless @element.can_be_read_by?(current_user || UneekPermission::PredefinedReceiver::Public.instance)
      elsif action_name == 'import'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to import"
      else
        super
      end
    end

  end

end
