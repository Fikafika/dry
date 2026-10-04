class Api::BaseController < ApplicationController

  include ExceptionHandler
  include SidekiqThrottle
  include EnableNotification
  include Honeypot
  include SkipUnknownAttributes
  include FindByIdOrName

  before_action :invalidate_permission_cache, if: :klass_is_controlled?

  skip_before_action :verify_authenticity_token, if: :skip_verify_authenticity_token?

  before_action :authenticate_before_find_element!, if: :authenticate_before_find_element?

  before_action :set_paper_trail_whodunnit

  before_action :find_element, only: [:show, :update, :destroy]

  before_action :verify_authenticity_token, if: :verify_authenticity_token_skipped?

  before_action :authenticate_after_find_element!, if: :authenticate_after_find_element?

  before_action :check_permissions, unless: :skip_permissions?

  def index
    @elements = elements
    if elements_stale?
      render json: to_json_with_cache(@elements), status: :ok
    end
  end

  def new
    @element = scope.new(element_params)
    render json: to_json(@element), status: :ok
  end

  def create
    @element = scope.create!(element_params)
    render json: to_json(@element), status: :created
  end

  def show
    if element_stale?
      render json: to_json_with_cache(@element), status: :ok
    end
  end

  def update
    @element.update!(element_params)
    render json: to_json(@element), status: :ok
  end

  def destroy
    @element.destroy!
    head :no_content
  end

  def count
    render json: scope.count, status: :ok
  end

  def update_all
    s = scope_for_permissions(scope, action_name)
    render json: s.update_all(element_params), status: :ok
  end

  def destroy_all
    s = scope_for_permissions(scope, action_name)
    render json: s.destroy_all, status: :ok
  end

  def find_or_create_by
    @element = scope.first
    if @element
      if element_stale?
        render json: to_json_with_cache(@element), status: :ok
      end
    else
      @element = scope.create!(element_params)
      render json: to_json(@element), status: :created
    end
  end

  private

  def find_element
    @element = scope.find(params[:id])
  end

  def elements
    s = scope
    s = scope_for_permissions(s, action_name)
    s = s.order(order_params) if order_params
    s = s.page(pagination_params[:page]).per(pagination_params[:per])
    s = s.limit(limit_params) if limit_params
    return s.all
  end

  def to_json(element) # redefined in subclasses
    element.to_json
  end

  def element_params
    p = params.permit![element_params_key]
    result = p ? p.to_unsafe_hash.except(special_param_keys) : {}.with_indifferent_access
    if params['action'] == 'new'
      result.keys.each do |k|
        if k.end_with?('_ids') && result[k].is_a?(Hash)
          result[k] = result[k].to_h.with_num_keys_to_array
        end
      end
    end
    remove_unpermitted_element_params(result, unpermitted_element_params)
    result
  end

  def special_param_keys
    ['only', 'include', 'where', 'where_not', 'scopes']
  end

  def element_params_key
    controller_name.singularize
  end

  def remove_unpermitted_element_params(element_params, unpermitted)
    return unless element_params

    if element_params.is_a?(Array)
      element_params.each do |e|
        remove_unpermitted_element_params(e, unpermitted)
      end
    else
      unpermitted&.each do |k, v|
        if v.is_a?(Hash)
          remove_unpermitted_element_params(element_params[k], v)
        else
          element_params.delete(k)
        end
      end
    end
  end

  def unpermitted_element_params
    case action_name
    when 'new'
      unpermitted_element_params_for_new
    when 'create'
      unpermitted_element_params_for_create
    when 'update'
      unpermitted_element_params_for_update
    end
  end

  def unpermitted_element_params_for_new
    unpermitted_element_params_for_create
  end

  def unpermitted_element_params_for_create
  end

  def unpermitted_element_params_for_update
    {
      'id' => nil,
      'created_at' => nil,
      'updated_at' => nil,
      'deleted_at' => nil,
    }
  end

  def scope
    result = base_scope
    result = result.where(where_params) unless where_params.empty?
    result = result.where.not(where_not_params) unless where_not_params.empty?
    scopes_params.each do |s|
      raise ActionController::RoutingError.new('Forbidden') unless allowed_scopes.include?(s[:name])
      result = result.send(s[:name], *s[:args])
    end
    return result
  end

  def base_scope
    klass
  end

  def klass
    begin
      @klass ||= controller_class_name_to_klass_name.constantize
    rescue NameError
      raise "Fail to find klass from controller name. It should be re-implemented because controller name doesn't match a model name"
    end
  end

  def klasses
    [klass]
  end

  def base_scopes
    [base_scope]
  end

  def controller_class_name_to_klass_name
    self.class.name.gsub(/^Api::/, '').gsub(/Controller$/, '').singularize
  end

  def controller_class_name_to_association_name
    # can be used in order to redefine base_scope
    self.class.name.demodulize.gsub(/Controller$/, '').underscore
  end

  def scopes_params
    @scopes_params ||= params[:scopes]&.permit!&.to_h&.with_num_keys_to_array&.map do |h|
      h[:args] = h[:args].with_num_keys_to_array if h[:args].is_a?(Hash)
      h
    end || []
  end

  def where_params
    @where_params ||= nilify_blanks(params[:where]&.permit!&.except(*where_exceptions) || {})
  end

  def where_not_params
    @where_not_params ||= nilify_blanks(params[:where_not]&.permit!&.except(*where_exceptions) || {})
  end

  def nilify_blanks(where_params)
    unless @nilify_blanks
      case params[:nilify_blanks]
      when String
        @nilify_blanks = Array(params[:nilify_blanks])
      else
        @nilify_blanks = []
      end
    end
    @nilify_blanks.each do |param|
      if where_params.has_key?(param) && where_params[param].blank?
        where_params[param] = nil
      end
    end
    return where_params
  end

  def order_params
    return @order_params if @order_params
    if params[:order].is_a?(String)
      @order_params = params[:order]
    elsif params[:order].is_a?(ActionController::Parameters)
      order_limit_params = params[:order].permit!.to_h
      order_limit_params.each do |k,v|
        order_limit_params[k] = v.to_sym
      end
      @order_params = order_limit_params.symbolize_keys
    end
    return @order_params
  end

  def limit_params
    params[:limit]
  end

  def allowed_scopes
    []
  end

  def where_exceptions
    params[:action].in?(collection_actions) ? [] : ['id']
  end

  def collection_actions
    ['index', 'count', 'update_all', 'destroy_all']
  end

  def pagination_params
    @pagination_params ||= params.slice('page', 'per').permit!
  end

  concerning :Cache do

    def element_stale?
      return true unless cache_enabled?
      return true unless element_for_cache
      last_modified = element_for_cache.updated_at || Time.at(0)
      return stale?(last_modified: last_modified.utc, etag: cache_key)
    end
    alias_method :elements_stale?, :element_stale?

    def to_json_with_cache(element)
      if cache_enabled? && element_for_cache
        Rails.cache.fetch(cache_key) do
          to_json(element)
        end
      else
        to_json(element)
      end
    end

    def cache_enabled? # redefine in subclasses
      return false
    end

    def cache_key
      @cache_key ||= "#{element_for_cache.cache_key_with_version}-#{cache_params.to_s.hash}#{@elements&.length || 1}"
    end

    def element_for_cache
      @element_for_cache ||= case action_name
      when 'show'
        @element
      when 'index'
        if @elements&.any?
          @elements.max_by{|e| e.updated_at || Time.at(0)}
        end
      end
    end

    def cache_params
      result = params.slice(*cache_param_keys)
      result.merge!(manifest_updated_at: manifest_updated_at) if klass_is_controlled?
      return result
    end

    def cache_param_keys
      ['klass_name', 'id', 'page', 'per', 'action'] + special_param_keys
    end

    def manifest_updated_at
      if klass_is_controlled?
        s = manifest_scope
        if s
          result = s.pluck(:updated_at).first
          return result&.to_fs(:usec) || Time.at(0)
        else
          Time.at(0)
        end
      else
        Time.at(0)
      end
    end

    def manifest_scope
      nil
    end

    def manifest_scope_for_schema_name(name)
      UneekPermission::Manifest.joins(community: {schema: {}}).where(schema: {name: name})
    end

    def manifest_scope_for_schema_id(id)
      UneekPermission::Manifest.joins(:community).where(community: {schema_id: id})
    end

  end

  concerning :Authentication do

    def authenticate_before_find_element?
      true
    end

    def authenticate_after_find_element?
      false
    end

    def authenticate_before_find_element!
      authenticate_user!
    end

    def authenticate_after_find_element!
      authenticate_user!
    end

    def skip_verify_authenticity_token?
      false
    end

    def verify_authenticity_token_skipped?
      false
    end

  end

  concerning :Jwt do
    class_methods do
      def skip_verify_authenticity_token_for_jwt
        skip_before_action :verify_authenticity_token, if: :has_jwt_header?
        before_action :verify_authenticity_token_after_authenticate_user, unless: :authenticated_with_jwt_without_session?
      end
    end

    included do
      alias_method :verify_authenticity_token_after_authenticate_user, :verify_authenticity_token
    end

    def has_jwt_header?
      request.headers[::User.jwt_header_name].present?
    end

    def authenticated_with_jwt_without_session?
      request.env['warden'].winning_strategy.is_a?(::Devise::Strategies::JwtHeaderAuthenticatable) && (!session.id || request.session_options[:renew])
    end
  end

  concerning :Versioning do

    def info_for_paper_trail
      result = super

      if params[:versioning]
        if params[:versioning][:source_id] && params[:versioning][:source_type]
          result[:source_type] = params[:versioning][:source_type]
          result[:source_id] = params[:versioning][:source_id]
        elsif params[:versioning][:source_attributes] && respond_to?(:id?)
          attrs = params[:versioning][:source_attributes].permit!.to_unsafe_hash
          raise 'not an uuid' unless id?(attrs[:id].to_s)
          source = ExternalSource.create_with(attrs.except(:id)).find_or_create_by!(id: attrs[:id])
          if source
            result[:source_type] = source.class.name
            result[:source_id] = source.id
          end
        end
      end

      return result
    end

  end

  concerning :Authorization do

    def skip_permissions?
      !klass_is_controlled? || current_user_is_admin?
    end

    def current_user_is_admin?
      return @current_user_is_admin if @current_user_is_admin
      schema_name = params[:schema_name] || params[:schema_id]
      schema_name = schema_name&.classify_permalink unless id?(schema_name)
      @current_user_is_admin = current_user&.admin?(schema_name)
      return @current_user_is_admin
    end

    def klass_is_controlled?
      @klass_is_controlled ||= klass.present? && klass.include?(UneekPermission::ControlledKlass)
    end

    def check_permissions
      case action_name
      when 'show', 'count'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to read this object" unless @element.can_be_read_by?(current_user)
      when 'create'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to create this object" unless klass.new(element_params).can_be_created_by?(current_user)
      when 'update'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to update this object" unless @element.can_be_updated_by?(current_user, **element_params)
      when 'destroy'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to delete this object" unless @element.can_be_deleted_by?(current_user)
      when 'update_all'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to update these objects" unless klass.can_update_scope?(scope, current_user, element_params.keys)
      when 'destroy_all'
        raise UneekPermission::UnauthorizedAction, "You are not allowed to delete these objects" unless klass.can_delete_scope?(scope, current_user)
      end
    end

    SCOPE_FOR_ACTION = {
      'index' => :for_user,
      'update_all' => :updatable_data,
      'destroy_all' => :deletable_data,
    }

    def scope_for_permissions(s, action_name)
      result = s
      unless skip_permissions?
        if SCOPE_FOR_ACTION.has_key?(action_name)
          u = current_user || ::UneekPermission::PredefinedReceiver::Public.instance
          result = result.send(SCOPE_FOR_ACTION[action_name], u)
        else
          raise ActionController::NotImplemented, "Permission scope not implemented for #{action_name}"
        end
      end
      result
    end

    def invalidate_permission_cache
      klass&.clear_permission_cache
    end

  end

end
