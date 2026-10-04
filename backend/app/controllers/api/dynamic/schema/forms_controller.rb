class Api::Dynamic::Schema::FormsController < Api::Dynamic::Schema::BaseController
  include LoadSchema
  include EnableWaitForCompletedJobs

  prepend_around_action :load_schema, only: [:show, :submit, :save_as_draft, :submit_all], if: :load_schema?

  skip_around_action :sidekiq_throttle_admin, only: [:submit, :submit_all]
  around_action :sidekiq_throttle_user, only: [:submit, :submit_all]

  before_action :protect_from_spam, only: [:submit]
  prepend_before_action(only: [:submit, :duplicate, :save_as_draft]) { find_element }
  before_action :prepare_form, only: [:show, :submit, :save_as_draft]
  before_action :perform_async, only: [:submit_all], if: -> { params[:async] }

  around_action :enable_wait_for_completed_jobs, only: [:submit]
  skip_around_action :enable_wait_for_completed_jobs, only: [:submit], if: -> { @element&.async_submission? }

  def submit
    form = @element
    if form.submit(params.to_unsafe_hash)
      render json: success_response, status: :ok
    else
      if form.forbidden?
        render json: form.submission_errors, status: :forbidden
      else
        render json: form.submission_errors, status: :unprocessable_content
      end
    end
  end

  def save_as_draft
    form = @element
    if form.save_as_draft(params.to_unsafe_hash)
      render json: {}, status: :ok
    else
      render json: {}, status: :unprocessable_content
    end
  end

  def submit_all
    raise 'only async is supported'
  end

  def duplicate
    element = @element.duplicate!
    render json: to_json(element), status: :created
  end

  private

  def load_schema?
    case action_name
    when 'show'
      return !!params.dig(:include, :loaded_elements)
    else
      true
    end
  end

  def schema_name # used by load_schema
    schema.name
  end

  def base_scope
    if params[:klass_id]
      super.where(klass_name: schema_klass_name)
    else
      super
    end
  end

  def controller_class_name_to_klass_name
    super.gsub('::Schema::', '::')
  end

  def element_params
    result = super
    result.delete(:klass_id)
    return result
  end

  def schema_klass
    @schema_klass ||= find_by_id_or_name(schema.klasses, params[:klass_id], :classify)
  end

  def schema_klass_name
    "D::#{schema.name}::#{schema_klass.name}"
  end

  def find_element
    current_user # TODO why User.current is not set without this ?
    @element = Dynamic::Form.find(params[:id])
  end

  def perform_async
    worker_klass = ::Dynamic::Record.const_get("#{action_name.classify}Worker")
    notification = create_notification
    perform_params = {
      klass_name: schema_klass_name,
      form_id: params[:id],
      form_params: params[:form]&.permit!&.to_h.merge(batch_id: notification.id),
      params: params[:relation_scope]&.permit!&.to_h,
      user_id: User.current.id,
      notification: notification,
    }.deep_stringify_keys
    perform_params['on_conflict_element_id'] = params[:on_conflict_element_id] if params[:on_conflict_element_id].present?
    worker_klass.perform_async(perform_params)
    render json: notification, status: :accepted
  end

  def create_notification
    dynamic_klass = schema_klass_name.safe_constantize
    notification_klass = dynamic_klass.module_parent::R::Notification
    return notification_klass&.create!(
      id: UUID7.generate,
      user_id: User.current.id,
      klass_name: "Bulk::#{action_name.classify}",
      total: params.dig(:relation_scope, :where, :id)&.count || dynamic_klass.count,
      data: {klass_name: schema_klass_name, form_name: params[:form_name]},
      can_cancel: true,
    )
  end

  def where_exceptions
    super + ['klass_id']
  end

  def allowed_scopes
    super + ['with_action']
  end

  def prepare_form
    case action_name
    when 'show'
      prepare_form_options
      if params.dig(:include, :loaded_elements)
        prepare_form_source_and_target_records
        prepare_form_records
      end
    when 'submit'
      prepare_form_options
      prepare_form_source_and_target_records
    when 'save_as_draft'
      prepare_form_source_and_target_records
    end
  end

  def prepare_form_options
    case action_name
    when 'show'
      options = params.dig(:where, :options)
      if options
        options = options.to_unsafe_hash.symbolize_keys
        options.delete(:find_similar) # prevent show unauthorize data (particularly when restore)
      end
    when 'submit'
      options = params[:options]
      if options
        options = options.to_unsafe_hash.symbolize_keys
        options[:find_similar] = true unless options.has_key?(:find_similar)
        options.delete(:restore) # don't restore params on submit, only use submitted params
      end
    end
    @element.options.deep_merge!(options) if options&.any?
  end

  def prepare_form_records
    @element.opening = true
    @element.load_and_build_records(params.to_unsafe_hash) # already done in submit
  end

  def prepare_form_source_and_target_records
    @element.source_record = find_record(:source)
    @element.target_record = find_record(:target)
  end

  def find_record(prefix)
    record_id = params.dig(:where, :"#{prefix}_record_id") || params[:"#{prefix}_record_id"]
    return nil unless record_id.present?
    record_type = params.dig(:where, :"#{prefix}_record_type") || params[:"#{prefix}_record_type"]
    return nil unless record_type.present?

    klass = record_type.safe_constantize
    Rails.logger.info "unknown #{prefix} record type: #{record_type}" unless klass

    record = klass&.find(record_id)
    if klass&.include?(::UneekPermission::ControlledKlass) && !current_user_is_admin? && action_name == 'show'
      raise ::UneekPermission::UnauthorizedAction, "You are not allowed to read this object" unless record.can_be_read_by?(current_user || UneekPermission::PredefinedReceiver::Public.instance)
    end
    return record
  end

  def success_response
    form = @element
    { records: form.records.map{|r| {id: r.id, type: r.class.name} } }
  end

  def cache_enabled?
    action_name == 'show' && !params.dig(:include, :loaded_elements) && !params.dig(:include, :forbidden?) && !params.dig(:include, :can_be_updated_by_current_user?)
  end

  class Select2
    include ::Select2::ActiveRecord

    def results
      @results ||= klass.joins(translations: {})
                        .where(where_from_filters)
                        .where(params[:where]&.permit! || {})
                        .where("unaccent(LOWER(human_name)) LIKE unaccent(LOWER(?))", "%#{term}%")
                        .limit(100).all
    end

    def name_attribute
      return 'human_name'
    end
  end

  concerning :Versioning do

    included do
      before_action :set_source_to_paper_trail_controller_info, only: [:submit, :submit_all]
    end

    def set_source_to_paper_trail_controller_info
      return unless @element && ::PaperTrail.request.controller_info.is_a?(::Hash)
      ::PaperTrail.request.controller_info.merge!(
        source_type: @element.class.name,
        source_id: @element.id,
      )
    end

  end

  concerning :Authentication do

    def authenticate_before_find_element?
      false
    end

    def authenticate_after_find_element?
      case action_name
      when 'show'
        !(public_form? || params.dig(:include, :theme))
      when 'submit', 'save_as_draft', 'submit_all'
        !public_form?
      else
        true
      end
    end

    def skip_verify_authenticity_token?
      action_name.in?(['save_as_draft', 'submit', 'submit_all'])
    end

    def verify_authenticity_token_skipped?
      !public_form? && skip_verify_authenticity_token?
    end

  end

  concerning :Authorization do

    def skip_permissions?
      super || requesting_show_or_submit_for_public_form || requesting_form_theme
    end

    def requesting_show_or_submit_for_public_form
      public_form? && action_name.in?(['show', 'submit'])
    end

    def public_form?
      @is_public_form ||= @element&.is_public?
    end

    def requesting_form_theme
      action_name == 'show' && params.dig(:include, :theme)
    end

    def public_schema_actions
      super + ['save_as_draft', 'submit', 'submit_all']
    end

  end

end
