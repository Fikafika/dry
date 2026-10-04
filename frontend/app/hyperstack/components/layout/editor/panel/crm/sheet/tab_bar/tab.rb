class Layout
  class Editor
    module Panel
      module Crm
        module Sheet
          module TabBar
            module Tab
              class Base < Panel::Base
                include Associations

                render { content }

                def parameters
                  return unless schema_klass
                  association_id
                  name
                  icon
                  translations
                  if current_schema_association&.name.nil? && !record.children.empty?
                    all_tab_assos_selector
                  end
                  building_buttons
                end

                def association_id
                  ::Form::Element::Attribute::Enum(
                    attribute_name: 'association_id',
                    label: I18n.t('activerecord.models.dynamic/schema/association/base.one'),
                    placeholder: I18n.t('shared.all_f'),
                    possible_values: possible_associations,
                  ).on(:change) do |value, form|
                    form.change!(form) # for update record.component_params
                    form.submission.write_from_user(['element', 'component_params', 'icon'], default_icon)
                    form.submission.write_from_user(['element', 'component_params', 'name'], current_schema_association&.name || 'all')
                    form.submission.write_from_user(['element', 'component_params', 'translations', 'fr', 'title'], current_schema_association&.human_name_fr)
                    form.submission.write_from_user(['element', 'component_params', 'translations', 'en', 'title'], current_schema_association&.human_name_en)
                    mutate
                  end
                end

                def all_assoc
                  @all_assoc ||= schema_klass.associations.select {|a| a.type == 'HasMany'}
                end

                def default_icon
                  current_target_klass&.icon || 'list'
                end

                def current_target_klass
                  target_klass_id = current_schema_association&.target_klass_id
                  return unless target_klass_id
                  return schema.klasses.detect{|k| k.id == target_klass_id}
                end

                def current_targets_list_klasses
                  schema_klasses = []
                  return if all_assoc.empty?
                  all_assoc.each do |value|
                    schema_klasses.append(schema.klasses.detect{|k| k.id == value.target_klass_id})
                  end
                  return schema_klasses
                end

                def name
                  ::Form::Element::Attribute::String(
                    attribute_name: 'name',
                    editor: 'hidden',
                  )
                end

                def icon
                  Form::Element::Attribute::Icon(
                    attribute_name: 'icon',
                  )
                end

                def current_schema_association
                  return unless current_association_id
                  schema_klass.associations.detect{|a| a.id == current_association_id}
                end

                def current_association_id
                  record.component_params[:association_id]
                end

                def translations
                  ::Form::Element::Attribute::Hash(
                    attribute_name: 'translations',
                    mode: 'nested_form',
                  ) do
                    I18n.available_locales.each do |lang|
                      ::Form::Element::Attribute::Hash(
                        attribute_name: lang,
                        mode: 'nested_form',
                      ) do
                        ::Form::Element::Attribute::String(
                          attribute_name: 'title',
                          label: "#{I18n.t('crm.sheet.toolbar.title')} #{lang}",
                        )
                      end
                    end
                  end
                end

                def get_forms(klass)
                  if @_forms && block_given?
                    yield
                  else
                    Dynamic::Form.where(schema_id: schema.name, klass_name: klass).includes(translations: 1).all do |forms|
                      @_forms = forms
                      yield if block_given?
                    end
                  end
                end

                def fake_record_all_assoc
                  @fake_record_all_assoc ||= HyperResource::Base.new(all_assoc_selectors: all_assoc&.map{|a| a.id})
                end

                def actual_association_list
                  return all_assoc.filter_map do |a|
                    infinite_scroller_component = record.children.detect{|e| e.component == "InfiniteScroller"}
                    next unless infinite_scroller_component
                    schema_association_ids = infinite_scroller_component.component_params_converter_options[:schema_association_ids]
                    next unless schema_association_ids&.include?(a.id)
                    a.id
                  end
                end

                def all_tab_assos_selector
                  Form(record: fake_record_all_assoc) do
                    ::Form::Element::Attribute::MultipleEnum(
                      attribute_name: 'all_assoc_selectors',
                      label: I18n.t('crm.sheet.toolbar.all_tab.tom_select'),
                      editor: 'tom_select',
                      possible_values: all_assoc.map{|a| {label: a.human_name, value: a.id}},
                      default_value: actual_association_list,
                    ).on(:change) do |value|
                      @all_selected = all_assoc.filter_map{|a| a if value.include?(a.id)}
                      center_children_creation('list')
                    end
                  end
                end

                def center_children_creation(mode)
                  if current_schema_association&.name.nil?
                    all_association_ids = @all_selected.nil? ? all_assoc.map(&:id) : @all_selected.map(&:id)
                    klass_name = current_targets_list_klasses.map(&:const_absolute_name)
                  else
                    all_association_ids = nil
                    klass_name = current_target_klass.const_absolute_name
                  end
                  get_forms(klass_name) do
                    replace_elements_of_selected_element&.call(send("generate_#{mode}", @_forms, all_association_ids))
                  end
                end

                def building_buttons
                  if has_inverse_association?(element&.component_params[:name])
                    modes = ['list', 'datatable', 'transaction_lines']
                  else
                    modes = ['list']
                  end
                  DIV(class: 'dropdown') do
                    BUTTON(id: 'builder-dropdown', class: 'btn dropdown-toggle', 'data-toggle': 'dropdown', 'aria-haspopup': true,'aria-expanded': false) do
                      I18n.t('layout_editor.panel.build_children')
                    end
                    DIV(class: 'dropdown-menu', 'aria-labelledby': 'builder-dropdown') do
                      modes.each do |m|
                        A(href: "#build_#{m}", class: 'dropdown-item') do
                          I18n.t("layout_editor.panel.build.#{m}")
                        end.on(:click) do |event|
                          event.prevent_default
                          center_children_creation(m)
                        end
                      end
                    end
                  end
                end

                def toolbar_element(element, forms)
                  for_all_tab = current_schema_association&.name.nil?
                  if for_all_tab
                    association_names = @all_selected.map(&:name)
                    selected_forms = forms.select do |f|
                      klass_name == f.association_klass_name && association_names.include?(f.association_name)
                    end
                  else
                    selected_forms = forms.select do |f|
                      f.association_klass_name == klass_name && f.association_name == current_schema_association.name
                    end
                  end
                  {
                    component: 'Toolbar',
                    component_params: {
                      class: 'w-100 mt-2 mb-2',
                    },
                    children_attributes: [
                      {
                        component: 'Crm::Sheet::NewItemButton',
                        component_params_converter_type: 'Crm::Sheet::NewItemButton::ParamsConverter',
                        component_params: {
                          class: 'pull-right'
                        },
                        children_attributes: selected_forms.map do |f|
                          {
                            component: 'Toolbar::Dropdown::Item',
                            component_params_converter_type: 'Crm::Sheet::NewItemButton::DropdownItem::ParamsConverter',
                            component_params_converter_options: {
                              form_id: f.id,
                              klass_name: f.klass_name,
                              translations: {
                                fr: { text: f.human_name_fr },
                                en: { text: f.human_name_en },
                              }
                            }
                          }
                        end
                      }
                    ]
                  }
                end

                def generate_datatable(forms)
                  return Proc.new { |element|
                    [
                      toolbar_element(element, forms),
                      {
                        component: 'Crm::Sheet::Datatable',
                        component_params_converter_type: 'Crm::Sheet::Datatable::ParamsConverter',
                        component_params_converter_options: {
                          schema_association: element&.component_params[:association_id],
                        },
                      }
                    ]
                  }
                end

                def generate_list(forms, associations)
                  return Proc.new do |element|
                    [
                      toolbar_element(element, forms),
                      {
                        component: 'InfiniteScroller',
                        component_params: {
                          class: 'container-fluid',
                        },
                        component_params_converter_options: {
                          schema_association_ids: associations ? associations : Array(element&.component_params[:association_id])
                        },
                        component_params_converter_type: 'Crm::Sheet::TabBar::Tab::InfiniteScrollerParamsConverter',
                        children_attributes: [{
                          component: 'DIV',
                          component_params: { class: 'row border-bottom' },
                          children_attributes: [{
                            component: 'DIV',
                            component_params: { class: 'col d-flex pr-0' },
                            children_attributes: [{
                              component: 'DIV',
                              component_params: { class: 'w-100 mt-2 mb-2 clearfix' },
                              children_attributes: [{
                                component: 'Crm::Sheet::Item',
                                component_params: {},
                                component_params_converter_type: 'Crm::Sheet::Item::ParamsConverter',
                              }]
                            },{
                              component: 'DIV',
                              component_params: {},
                              children_attributes: [{
                                component: 'IconButton',
                                component_params: {},
                                component_params_converter_type: 'Crm::Sheet::Item::EditIconParamsConverter',
                              }]
                            },{
                              component: 'Crm::Sheet::Item::Menu',
                              component_params: {},
                              component_params_converter_type: 'Crm::Sheet::Item::Menu::ParamsConverter',
                            }]
                          }],
                        }],
                      }
                    ]
                  end
                end

                def generate_transaction_lines(forms)
                  return Proc.new do |element|
                    [
                      toolbar_element(element, forms),
                      {
                        component: 'Crm::TransactionLine::Table',
                        component_params_converter_type: 'Crm::TransactionLine::Table::ParamsConverter',
                        component_params: {
                          class: 'container-fluid',
                        },
                        component_params_converter_options: {
                          schema_association_id: element&.component_params[:association_id],
                          columns: [],
                        },
                      },
                    ]
                  end
                end

              end
            end
          end
        end
      end
    end
  end
end
