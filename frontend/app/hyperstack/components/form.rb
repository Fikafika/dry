# backtick_javascript: true
require 'components/wait_for_completed_jobs'

class Form < HyperComponent
  include Hyperstack::Router::Helpers
  include WaitForCompletedJobs

  class << self
    attr_accessor :current
  end
  attr_accessor :page_counter
  attr_accessor :condition_elements
  attr_accessor :condition_attrs_to_clean
  attr_accessor :association_min
  attr_accessor :association_max
  attr_accessor :input_ids

  def initialize(*args)
    super
    @condition_elements = Set.new
    @condition_attrs_to_clean = {}
    @association_min = {}
    @association_max = {}
    @elements_waiting_for_data = {}
    @elements_mutated_after_data_loaded = Set.new
    @input_ids = Set.new
  end

  param :nested, default: false
  collect_other_params_as :other_params

  fires :start
  fires :loaded
  fires :submit
  fires :success
  fires :error
  fires :cancel
  fires :enable
  fires :change
  fires :finish
  fires :save_as_draft
  fires :load_error

  render do
    ErrorBoundary do
      content
    end
  end

  before_mount do
    observe record if record
    init_current
  end

  before_new_params do |next_props|
    if next_props[:record] != record || (@dynamic_form && (next_props[:dynamic_form] != @dynamic_form || next_props[:dynamic_form_id] != @dynamic_form.id))
      reset_without_mutate(next_props)
      @dynamic_form = nil
      @prefix_path = nil
      mutate
    end
  end

  before_render do
    if !@was_started && (dynamic_form || record)&.loaded?
      @was_started = true
      start!(self)
    end
  end

  after_update do
    @reseting = false
    if !@was_loaded && (dynamic_form || record)&.loaded?
      @was_loaded = true
      loaded!(self)
    end
  end

  def content
    init_current
    DIV(class: other_params[:className], style: other_params[:style]) do
      if dynamic_form && (dynamic_form.not_found? || dynamic_form.unauthorized?)
        status = {404 => 'not_found', 401 => 'unauthorized'}
        DIV(class: 'alert alert-warning') do
          I18n.t("activerecord.exceptions.#{status[dynamic_form.status_code]}", model_name: I18n.t('shared.object'))
        end
      else
        if dynamic_form&.mode == 'input'
          ::Honeypot.honeypot_fields.each do |f|
            ::Form::Element::Honeypot(
              form: self,
              attribute_name: f,
            )
          end
        end
        elements.each do |c|
          render_child(c)
        end
      end
      children.each do |c|
        render_child(c)
      end
    end
  end

  def init_current
    return if nested
    self.page_counter = 1
    self.class.current = self
  end

  def submit(transform_params: nil)
    if dynamic_form
      mutate @submitting = true

      params = submission.params
      params = transform_params.call(params) if transform_params

      promise = dynamic_form.submit(params.merge({
        check_important: submission.check_important,
        options: other_params[:dynamic_form_options] || {},
      }).merge(additional_submit_options)).then do |response|
        @response = response
        submission.status_code = response[:status_code]
        submission.check_important = false
        submission.errors = response[:errors] || {}
        if response[:success]
          update_cache(response[:records])
          stale_dynamic_form
        end
        @enabled = false if other_params[:enabled].nil?
        mutate @submitting = false
        scroll_to_first_element_with_error_after_render unless response[:success]

        if response[:success]
          success!(response, self)
        else
          error!(response, self)
        end
        response
      end
    elsif record
      mutate @submitting = true

      attrs = submission.params[submission.params.keys.first]
      attrs = transform_params.call(attrs) if transform_params

      promise = record.update(attrs).then do |response|
        @response = response
        submission.status_code = response[:status_code]
        submission.errors = record.errors || {}
        @enabled = false if other_params[:enabled].nil?
        @submitting = false
        mutate
        scroll_to_first_element_with_error_after_render unless response[:success]
        response[:success] ? success!(response, self) : error!(response, self)
        response
      end
    end
    submit!(submission)
    promise
  end

  def additional_submit_options
    if other_params[:dynamic_form_options]&.has_key?(:wait_for_elasticsearch)
      # backward compatibility with wait_for_elasticsearch
      return wait_for_completed_jobs_options
    end

    return other_params[:additional_submit_options] ? other_params[:additional_submit_options] : {}
  end

  def cancel
    reset
    go_to_first_page
    cancel!
  end

  def save_as_draft
    return unless dynamic_form
    mutate @submitting = true
    promise = dynamic_form.save_as_draft(submission.params).then do |response|
      @response = response
      submission.status_code = response[:status_code]
      submission.errors = response[:errors] || {}
      @enabled = false if other_params[:enabled].nil?
      stale_dynamic_form  if response[:success]
      mutate @submitting = false
      if response[:success]
        save_as_draft!
      end
      response
    end
  end

  def dynamic_form
    @dynamic_form = other_params[:dynamic_form] unless @dynamic_form

    if @dynamic_form
      if other_params['source_record']
        @dynamic_form.attributes['source_record'] = other_params['source_record']
      end
      if other_params['target_record']
        @dynamic_form.attributes['target_record'] = other_params['target_record']
      end
      unless other_params[:dynamic_form_id] && @dynamic_form.loaded? && @dynamic_form.stale
        return observe @dynamic_form
      end
    end

    if other_params[:dynamic_form_id]
      @dynamic_form = Dynamic::Form.load({
        id: other_params[:dynamic_form_id],
        schema_id: other_params[:schema_id],
        source_record_type: other_params[:source_record_type],
        source_record_id: other_params[:source_record_id],
        source_record: other_params[:source_record],
        target_record_type: other_params[:target_record_type],
        target_record_id: other_params[:target_record_id],
        target_record: other_params[:target_record],
        options: other_params[:dynamic_form_options] || {},
      }) do |form|
        if !form.loaded? && form.status_code
          form.stale!
          load_error!(form.status_code)
        end
      end
      observe @dynamic_form
    end

    return @dynamic_form
  end

  def record
    other_params[:record]
  end

  def enable
    return if @enabled
    enable!
    @enabled = true
    mutate
  end

  def enabled?
    if other_params[:enabled].nil?
      if enable_after_user_interaction?
        return !!@enabled
      else
        return true
      end
    else
      return other_params[:enabled]
    end
  end

  def enable_after_user_interaction?
    other_params[:enable_after_user_interaction]
  end

  def reset
    reset_without_mutate
    mutate
  end

  def reset_without_mutate(params = other_params)
    @reseting = true
    next_submission_page = submission.page
    @submission = submission_klass.new(params[:params])
    @submission.page = next_submission_page
    compute_initial_params(params[:params]) if params[:params].is_a?(Proc)
    @enabled = false
  end

  def reseting?
    @reseting
  end

  def submission
    return @submission if @submission
    @submission = submission_klass.new(other_params[:params])
    compute_initial_params(other_params[:params]) if other_params[:params].is_a?(Proc)
    return @submission
  end

  def compute_initial_params(params)
    params.call(Proc.new do |params_, data|
      @submission.write_initial_params(params_)
      @submission.data.merge!(data) if data
      mutate
    end)
  end

  def submission_klass
    if record
      RecordSubmission
    elsif dynamic_form
      DynamicFormSubmission
    else
      Submission
    end
  end

  def submitting?
    @submitting
  end

  def mode
    if dynamic_form
      return dynamic_form.mode
    else
      other_params[:mode] || :input
    end
  end

  def mutate_conditions
    self.condition_elements.map(&:mutate)
  end

  private

  def render_child(c, prefix_path = nil, record = self.record, conditions = nil, in_hash = nil, args = {})
    if child_has_param?(c, :form)
      args[:form] = self

      if record && child_has_param?(c, :record)
        args[:record] = record
      end
    end

    if child_has_param?(c, :prefix_path)
      input_prefix_path = `#{c.to_n}.props.input_prefix_path`
      prefix_path ||= self.prefix_path
      if input_prefix_path&.any? && prefix_path
        if input_prefix_path.length >= prefix_path.length
          prefix_path = prefix_path + input_prefix_path[prefix_path.length..-1]
        end
      end
      args[:prefix_path] = prefix_path
    end

    if conditions && child_has_param?(c, :conditions)
      args[:conditions] = conditions
    end

    if child_has_param?(c, :timestamp) # force refresh
      args[:timestamp] = next_timestamp
    end

    if !in_hash.nil? && child_has_param?(c, :in_hash)
      args[:in_hash] = in_hash
    end

    c.render(args)
  end

  def next_timestamp
    return @@next_timestamp if submitting? # prevent useless rerender
    @@next_timestamp ||= 0
    @@next_timestamp += 1
  end

  def child_has_param?(c, para)
    return false unless `#{c.to_n}.props`
    `#{c.to_n}.props.hasOwnProperty(#{para})`
  end

  def elements
    return [] unless dynamic_form&.loaded?

    @elements = []
    dynamic_form&.root_elements&.each do |element|
      e = convert_dynamic_form_element(element)
      @elements << e if e
    end

    @elements
  end

  def convert_dynamic_form_element(element)
    klass = "::Form::Element::#{element.type}".safe_constantize

    if klass.nil?
      puts "missing form element class for #{element.type}"
      return nil
    end

    if element.klass_name
      record = instantiate_record(element)
    end

    element_params = self.class.convert_dynamic_form_element_attributes(element)
    element_params[:record] = record

    result = klass.create_element(element_params) do
      r = []
      element.children.each do |c|
        e = convert_dynamic_form_element(c)
        r << e if e
      end
      r
    end

    return result
  end

  def ancestors_autocomplete_filters(element)
    return nil unless element

    result = {and: []}
    prefix_filters = []
    result[:and] << element.autocomplete_filters if element.autocomplete_filters
    parent_id = element.parent_id
    current_element = ['Association::HasMany', 'Association::BelongsTo'].include?(element.type) ? element : nil
    element_method_names = element.method_names&.dup || []
    if current_element
      element_method_names << current_element.attribute_name
    end
    element_method_names_size = element_method_names.size

    element_method_names.each_with_index do |attr, i|
      current_element = dynamic_form.element_by_id[parent_id] unless current_element
      break unless current_element
      parent_klass = current_element.klass_name&.safe_constantize
      break unless parent_klass
      inverse_of = nil
      if ['Association::HasMany', 'Association::BelongsTo'].include?(current_element.type) && i < element_method_names_size - 1
        reflection = parent_klass.reflect_on_association(current_element.attribute_name)
        inverse_of = reflection&.options ? reflection&.options[:inverse_of] : nil
        break unless inverse_of
      end

      if current_element.autocomplete_filters.present?
        f = change_attribute_key_filters(current_element.autocomplete_filters, prefix_filters&.join('.'))
        result[:and] << f unless result[:and].include?(f)
      end
      prefix_filters << inverse_of
      parent_id = current_element.parent_id
      current_element = nil
    end

    result = nil if result == {and: []}

    return result
  end

  def change_attribute_key_filters(filters, new_filters_key)
    return filters unless new_filters_key
    result = {}
    filters.each do |k, value|
      if value.is_a?(::Array)
        result[k] = value.map{|v| change_attribute_key_filters(v, new_filters_key)}
      elsif value.is_a?(::Hash)
        new_key = new_filters_key.present? ? "#{new_filters_key}.#{k}" : k
        result[new_key] = value
      end
    end
    return result
  end

  def self.convert_dynamic_form_element_attributes(element)
    {
      id: element.id,
      editor: element.editor,
      mode: element.mode,
      input_prefix: element.input_prefix, # needed?
      input_prefix_path: element.input_prefix_path,
      attribute_name: element.attribute_name,
      target_klass_names: element.target_klass_names,
      label: element.label || element.klass_name&.safe_constantize&.human_attribute_name(element.attribute_name),
      requirement: element.requirement,
      col_size: element.label_col_size,
      label_col_size: element.label_col_size,
      input_col_size: element.input_col_size,
      possible_values: element.values,
      sorting_attribute: element.sorting_attribute,
      sorting_type: element.sorting_type,
      autocomplete_filters: Proc.new{|form| form.ancestors_autocomplete_filters(element)},
      condition_formula: element.condition_formula,
      placeholder: element.watermark,
      help: element.help,
      text: element.text,
      css_classes: element.css_classes,
      attachments: element.attachments,
      disabled: to_bool(element.disabled),
      read_only: to_bool(element.read_only),
      default_value: element.default_value,
      force_default_value: to_bool(element.force_default_value, false),
      show_label: to_bool(element.show_label, true),
      show_value: to_bool(element.show_value, true),
      value_position: element.value_position,
      previous_button_text: element.previous_button_text,
      next_button_text: element.next_button_text,
      cancel_button_text: element.cancel_button_text,
      save_as_draft_button_text: element.save_as_draft_button_text,
      submit_button_text: element.submit_button_text,
      show_previous_button: to_bool(element.show_previous_button, true),
      show_next_button: to_bool(element.show_next_button, true),
      show_cancel_button: to_bool(element.show_cancel_button, true),
      show_save_as_draft_button: to_bool(element.show_save_as_draft_button, false),
      show_submit_button: to_bool(element.show_submit_button, true),
      min: element.min,
      max: element.max,
      values_limit: element.values_limit,
      compact: element.compact,
    }
  end

  def self.to_bool(value, default_value = false) # TODO HyperResource::Base.attribute() in order to properly cast boolean values and remove this
    value.nil? ? default_value : value && ![0, '0'].include?(value)
  end

  def instantiate_record(dynamic_element)
    input_prefix = dynamic_element.input_prefix

    if dynamic_form&.source_record && dynamic_form&.klass_name == dynamic_form.source_record.class.name # TODO improve
      record = dynamic_form.source_record
    end

    return record if record

    record = dynamic_form.record_for_element(dynamic_element, submission)

    if dynamic_form&.mode != 'read_only' && submission.errors.has_key?(input_prefix)
      record.errors = submission.errors[input_prefix]
    end

    return record
  end

  def prefix_path
    if self.record
      @prefix_path ||= [self.record.class.member_params_key]
    elsif dynamic_form&.klass_name
      @prefix_path ||= [dynamic_form.klass_name.demodulize.underscore]
    end
  end

  def update_cache(records)
    return unless records

    records_klasses = records.map do |r|
      case r
      when Hash
        r[:type]&.safe_constantize
      when HyperResource::Base
        r.class
      end
    end.compact.uniq

    records_klasses.map{|r| r.try(:clear_cache) }
    n = records_klasses.first&.name
    if n&.start_with?('D')
      "#{n.split('::')[0..1].join('::')}::DynamicAssociation".safe_constantize&.update_cache([:all])
    end
  end

  def stale_dynamic_form
    if other_params[:source_record_id] # because it must be reloaded with new record values
      page_count # store @page_count before stale
      dynamic_form.stale!
    end
  end

  def change
    mutate_conditions
    change!(self)
  end

  def page_count
    return @page_count if @page_count
    return 0 unless data_loaded?
    @page_count = 0
    dynamic_form.elements.each{|e| @page_count += 1 if e.type&.end_with?('Layout::Page') } if dynamic_form
    @page_count += children.count{|e| d = e.type.JS[:displayName]; (d && d == 'Form::Element::Layout::Page') }
    @page_count = 1 if @page_count == 0
    return @page_count
  end

  def data_loaded?
    if d = dynamic_form
      return d.loaded?
    elsif r = record
      return r.new_record? || !r.loading?
    else
      return false
    end
  end

  def navigation_count
    return 0 unless dynamic_form&.loaded?
    return @navigation_count if @navigation_count
    @navigation_count = dynamic_form.elements.select{|e| e.type&.end_with?('Control::Navigation') }.length
    return @navigation_count
  end

  def go_to_previous_page
    return unless submission.page > 1
    submission.page -= 1
    mutate
  end

  def go_to_first_page
    submission.page = 1
    mutate
  end

  def go_to_next_page
    submission.page += 1
    if submission.page > page_count
      finish!(@response, self)
      go_to_first_page
    else
      mutate
    end
  end

  def go_to_page(n)
    return if n < 1 || n > page_count
    submission.page = n
    mutate
  end

  def scroll_to_first_element_with_error
    element = self.jq_node.find('.is-invalid').first
    if element # replaced by its label if found
      label = element.closest('.form-group').find('.control-label').first
      element = label if label
    end
    `#{element.to_n}[0].scrollIntoView({behavior: 'smooth'})` if element
  end

  def scroll_to_first_element_with_error_after_render
    $window.after(0.1) do # TODO find a better way
      scroll_to_first_element_with_error
    end
  end

  def mutate_element_after_data_loaded(element, promises)
    promises = [promises] unless promises.is_a?(Array)
    @elements_waiting_for_data[element] ||= []
    @elements_waiting_for_data[element].concat(promises)

    # form.after_render is called before its children finished to render
    # so we use a timer. Is there a better solution ?
    @data_loading_timer&.abort
    @data_loading_timer = $window.after(0.05) do
      mutate_elements_after_their_data_is_loaded
    end
  end

  def mutate_elements_after_their_data_is_loaded
    return unless @elements_waiting_for_data.any?

    to_mutate = @elements_waiting_for_data.keys
    promises = @elements_waiting_for_data.values.inject(&:concat).map do |v|
      v.is_a?(Promise) ? v : v.try(:__promise__)
    end.compact

    @elements_waiting_for_data.clear

    # how wait a limited time, render elements of resolved and render other later ?
    Promise.when(*promises).then do
      to_mutate.each do |e|
        next if @elements_mutated_after_data_loaded.include?(e) # prevent possible cycles
        @elements_mutated_after_data_loaded << e
        e.mutate
      end
    end
  end

  def value_can_be_changed?(path)
    return true # TODO implement properly for return false when path is not compatible with elements
  end

  def pages
    @pages ||= {}
  end

end
