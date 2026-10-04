class Layout::Manager < HyperComponent
  include Crm::WithPageTitleAndLayoutSelector

  param :klass
  param :layout_id
  param :menu_item_id
  param :rerender_after_create, default: true

  fires :created
  fires :deleted
  fires :updated
  fires :layout_changed
  fires :select_layout

  before_mount do
    initialize_manager_state
    @layout_listener_id = listen_to_layout_changes
  end

  before_unmount do
    LayoutEvent.off(:layout_changed, @layout_listener_id) if @layout_listener_id
  end

  def listen_to_layout_changes
    return unless defined?(LayoutEvent)
    LayoutEvent.on(:layout_changed) { mutate }
  end

  def current_menu_item
    @current_menu_item ||= begin
      schema_menu = User.current.menus.merge_where(
        schema_name: schema_name,
        name: 'crm'
      ).first
      schema_menu&.items&.detect { |item| item.id == menu_item_id }
    end
  end

  def new_layout_attrs
    result = {
      actions: 8, # TODO
      menu_item_id: menu_item_id,
      schema_id: schema_name,
      klass_name: klass.name,
    }

    if current_menu_item
      I18n.available_locales.each do |l|
        result[:"human_name_#{l}"] = current_menu_item.send(:"label_#{l}")
        result[:"human_name_#{l}"] ||= current_menu_item.send(:"label_fr") ||
                                       current_menu_item.send(:"label_en")
      end
    end
    result
  end

  def includes_for_manager
    {
      except: [
        'updated_when_schema_is_changed',
        'created_at',
        'updated_at',
        'deleted_at',
      ],
      include: {
        translations: {
          except: ['schema_id', 'dynamic_layout_id', 'created_at', 'updated_at']
        },
        elements: {
          except: [
            'created_at',
            'updated_at',
            'schema_id',
            'layout_id',
          ],
        },
      }
    }
  end

  def existing_layouts
    observe Dynamic::Layout
      .with_action('index')
      .for_menu_item(menu_item_id)
      .where(schema_id: schema_name, klass_name: klass.name)
      .includes(includes_for_manager)
      .order(id: :asc)
      .all
  end

  def is_last_layout?
    existing_layouts.count <= 1
  end

  def possible_layout_types
    exceptions = ['Crm::Chart::Index']
    ::Crm::Index::Base.subclasses.map(&:name).select { |t| !exceptions.include?(t) }
  end

  def icon_for_type(type_name) # TODO should icon be defined on component that inherite of Crm::Index::Base
    icons = {
      'table' => 'th',
      'grid' => 'th',
      'list' => 'address-card',
      'card' => 'id-card',
      'kanban' => 'columns',
      'timeline' => 'stream',
      'calendar' => 'calendar',
      'chart' => 'chart-bar',
      'dashboard' => 'chart-pie',
      'planner' => 'calendar-days',
      'file_manager' => 'file',
    }
    icons[type_name] || 'file-alt'
  end

  def label_for_type(type)
    type_name = type.split('::').last.underscore
    I18n.t("activerecord.values.dynamic/menu/item.mode.#{type_name}")
  end

  def clean_item_link(menu_item, layout)
    return unless menu_item.respond_to?(:link) && menu_item.link.present?
    original_link = menu_item.link.to_s
    cleaned_link = original_link.gsub(/([?&])l=#{Regexp.escape(layout.id.to_s)}(&|$)/) do
      if $1 == '?' && $2 == '&'
        '?'
      elsif $1 == '?' && $2 == ''
        ''
      elsif $1 == '&'
        ''
      end
    end
    cleaned_link = cleaned_link.gsub(/\?&/, '?').gsub(/&&+/, '&').gsub(/[?&]$/, '')
    if original_link != cleaned_link
      menu_item.update(link: cleaned_link)
      mutate
    end
  end

  def delete_layout(layout)
    clean_menu_references!(layout)
    layout.destroy.then do |result|
      if result
        deleted!(layout)
        LayoutEvent.emit(:layout_changed, { layout: layout, schema: schema_name, klass: klass.name })
        mutate
      end
    end
  end

  def clean_menu_references!(layout)
    clean_item_link(current_menu_item, layout)
  end

  def layout_deletable?(layout)
    !is_last_layout? && !(layout.respond_to?(:default) && layout.default)
  end

  def layout_has_dependencies?(layout)
    layout.respond_to?(:elements) && layout.elements.any?
  end

  def render_delete_button(layout)
    if !layout_deletable?(layout)
      render_locked_layout_indicator(layout)
    else
      render_simple_delete_button(layout)
    end
  end

  def render_locked_layout_indicator(layout)
    reason = if is_last_layout?
      I18n.t('layout.delete.is_last_layout')
    elsif layout.respond_to?(:default) && layout.default
      I18n.t('layout.delete.is_default')
    else
      I18n.t('layout.delete.cannot_delete')
    end
    BUTTON(
      class: 'btn btn-light btn-sm mb-1 disabled',
      title: reason,
      disabled: true
    ) do
      I(class: 'fas fa-lock text-secondary')
    end
  end

  def render_simple_delete_button(layout)
    BUTTON(
      class: 'btn btn-light btn-sm md-1',
      title: I18n.t('layout.delete.tooltip')
    ) do
      I(class: 'fas fa-trash')
    end.on(:click) do
      confirm_simple_delete(layout)
    end
  end

  def confirm_simple_delete(layout)
    Modal.confirm(
      title: I18n.t('layout.delete.confirm_title'),
      text: I18n.t('layout.delete.confirm_simple', name: layout.human_name),
      commit: I18n.t('shared._yes'),
      commitClass: 'btn-danger',
      cancel: I18n.t('shared._no')
    ) { delete_layout(layout) }
  end

  def initialize_manager_state
    @step = 1
    @selected_layout_id = nil
    @selected_type = nil
    @layout_for_config = nil
    @editing_layout_id = nil
  end

  def reset_state
    mutate do
      @step = 1
      @selected_layout_id = nil
      @selected_type = nil
      @layout_for_config = nil
      @editing_layout_id = nil
    end
  end

  def selection_made?
    @selected_layout_id.present? || @selected_type.present?
  end

  def go_to_configuration
    prepare_layout_configuration
    mutate { @step = 2 }
  end

  def go_to_selection
    mutate {
      @step = 1
      @editing_layout_id = nil
    }
  end

  def cancel_edit
    @editing_layout_id = nil
    mutate
  end

  def select_for_duplication(layout)
    return if @editing_layout_id.present?
    mutate do
      @selected_layout_id = layout.id
      @selected_type = nil
    end
  end

  def select_for_creation(type)
    return if @editing_layout_id.present?
    mutate do
      @selected_type = type
      @selected_layout_id = nil
    end
  end

  def prepare_layout_configuration
    @layout_for_config = if @selected_layout_id
      prepare_for_duplication
    elsif @selected_type
      prepare_for_creation
    end
  end

  def prepare_for_duplication
    layouts_array = existing_layouts.to_a
    source_layout = layouts_array.find { |l| l.id == @selected_layout_id }
    return unless source_layout
    new_layout_attrs = source_layout.attributes.except('id', 'created_at', 'updated_at', 'default')
    I18n.available_locales.each do |locale|
      original_name = source_layout.send("human_name_#{locale}") || source_layout.human_name
      copy_suffix = I18n.t('layout.copy')
      new_layout_attrs["human_name_#{locale}"] = "#{original_name} - #{copy_suffix}"
    end
    new_layout_attrs[:elements_attributes] = source_layout.elements.map do |element|
      e = element.attributes.except('id', 'layout_id', 'created_at', 'updated_at', 'default')
      e[:duplicate_related_records] = true
      e
    end
    duplicated = Dynamic::Layout.new(new_layout_attrs)
    duplicated.persisted = false
    duplicated
  end

  def prepare_for_creation
    attrs = new_layout_attrs
    attrs[:elements_attributes] = [{
      component: @selected_type,
      component_params_converter_type: ::Layout::ParamsConverter.converters_for[@selected_type]&.first,
    }]
    I18n.available_locales.each do |locale|
      attrs[:"human_name_#{locale}"] = label_for_type(@selected_type)
    end
    layout = Dynamic::Layout.new(attrs)
    layout.persisted = false
    layout
  end

  def change_layout(layout_id_to_use)
    return if layout_id_to_use == 'new'
    select_layout!(layout_id_to_use)
  end

  render do
    global_toolbar_left
    DIV(class: 'layout-manager pt-4') do
      DIV(class: 'container') do
        case @step
        when 1
          render_selection_screen
        when 2
          render_configuration_screen
        end
      end
    end
  end

  private

  def render_selection_screen
    DIV do
      render_existing_layouts if existing_layouts.any?
      render_creation_types if possible_layout_types.any?
      render_selection_actions
    end
  end

  def render_existing_layouts
    H4(class: 'mb-3') { I18n.t('layout.duplicate.title') }
    DIV(class: 'layouts-list mb-5 row') do
      existing_layouts.each do |layout|
        if @editing_layout_id == layout.id
          render_edit_mode(layout)
        else
          render_layout_card(layout)
        end
      end
    end
  end

  def render_creation_types
    H4(class: 'mb-3') { I18n.t('layout.create.title') }
    DIV(class: 'row') do
      possible_layout_types.each do |type|
        render_creation_card(type)
      end
    end
  end

  def render_layout_card(layout)
    is_selected = @selected_layout_id == layout.id
    card_classes = "card mb-3 cursor-pointer hover-shadow #{'border-primary border-2' if is_selected}"
    element_type = layout.elements.first&.component&.split('::')&.last&.underscore
    DIV(class: 'col-md-6 col-lg-4 mb-3') do
      DIV(class: card_classes) do
        DIV(class: 'card-body d-flex justify-content-between align-items-center flex-column') do
          DIV(class: 'd-flex align-items-center flex-grow-1') do
            I(class: "fas fa-#{icon_for_type(element_type)} fa-3x text-primary mb-3")
          end
          DIV(class: 'd-flex align-items-center flex-grow-1') do
            DIV { H6(class: 'card-title mb-0') { layout.human_name } }
          end
          DIV(class: 'layout-actions d-flex gap-2 flex-column position-absolute', style: {right: '15px'}) do
            render_edit_button(layout)
            render_delete_button(layout)
          end
        end
      end.on(:click) { select_for_duplication(layout) }
    end
  end

  def render_creation_card(type)
    is_selected = @selected_type == type
    type_name = type.split('::').last.underscore
    card_classes = "card h-100 cursor-pointer hover-shadow text-center #{'border-primary border-2' if is_selected}"
    DIV(class: 'col-md-6 col-lg-4 mb-3 mt-3') do
      DIV(class: card_classes) do
        DIV(class: 'card-body') do
          I(class: "fas fa-#{icon_for_type(type_name)} fa-3x text-primary mb-3")
          H6(class: 'card-title mb-0') { label_for_type(type) }
        end
      end.on(:click) { select_for_creation(type) }
    end
  end

  def render_edit_button(layout)
    BUTTON(
      class: 'btn btn-light btn-sm mb-1',
      title: I18n.t('layout.edit.tooltip')
    ) do
      I(class: 'fas fa-edit')
    end.on(:click) do |e|
      e.stop_propagation
      @editing_layout_id = layout.id
      mutate
    end
  end

  def render_edit_mode(layout)
    DIV(class: 'col-md-6 col-lg-4') do
      DIV(class: 'card mb-3 cursor-pointer border-primary') do
        DIV(class: 'card-body') do
          Form(record: layout) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
            )
            Form::Element::Control::Navigation(
              show_previous_button: false,
              show_next_button: false,
            )
          end.on(:cancel) do
            cancel_edit
          end.on(:success) do |form|
            @editing_layout_id = nil
            LayoutEvent.emit(:layout_changed, { layout: layout, schema: schema_name, klass: klass.name })
            mutate
          end
        end
      end
    end
  end

  def render_selection_actions
    DIV(class: 'd-flex justify-content-end mt-4 mb-4') do
      BUTTON(class: 'btn btn-primary ml-2', disabled: !selection_made?) do
        I18n.t('layout.create.next')
      end.on(:click) { go_to_configuration }
    end
  end

  def render_configuration_screen
    return unless @layout_for_config
    DIV(class: 'card') do
      DIV(class: 'card-body') do
        DIV(class: 'h5 card-title mb-3') { I18n.t('layout.create.configure_layout') }
        render_type_info if @layout_for_config.elements_attributes&.first&.[](:component)&.present?
        render_configuration_form
      end
    end
  end

  def render_type_info
    DIV(class: 'mb-3 p-3 bg-light rounded') do
      STRONG(class: 'mr-1') { "#{I18n.t('layout.create.selected_type')}:" }
      SPAN(class: 'text-primary') do
        label_for_type(@layout_for_config.elements_attributes.first[:component])
      end
    end
  end

  def render_configuration_form
    Form(record: @layout_for_config) do
      Form::Element::Attribute::TranslatableString(
        attribute_name: 'human_name',
        required: true,
        values: @layout_for_config.attributes.select { |k, _v| k.start_with?('human_name_') }
      )
      DIV(class: 'd-flex gap-2 mt-4 justify-content-end') do
        BUTTON(class: 'btn btn-light', type: 'button') do
          I18n.t('shared.back')
        end.on(:click) { go_to_selection }
        BUTTON(class: 'btn btn-primary ml-2', type: 'button') do
          I18n.t('layout.validate')
        end.on(:click) { save_layout }
      end
    end.on(:change) do |form|
      @layout_for_config.attributes.merge!(form.submission.params['layout'])
    end
  end

  def save_layout
    @layout_for_config.save.then do |result|
      if result
        LayoutEvent.emit(:layout_changed, { layout: @layout_for_config, schema: schema_name, klass: klass.name })
        created!(@layout_for_config)
        reset_state if rerender_after_create
      end
    end
  end
end
