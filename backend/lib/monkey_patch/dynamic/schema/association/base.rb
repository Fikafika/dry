ActiveSupport.on_load(:dynamic_schema_association_base) do

  module DefineReflectionsWithDefaultElasticsearchFilters
    def define_reflections
      super
      default_elasticsearch_filters = self.default_elasticsearch_filters
      names = [const_association_name]
      names << const_association_name_with_deleted if with_deleted?
      names.each do |name|
        reflection = self.owner_klass.const.reflect_on_association(name)
        next unless reflection
        reflection.define_singleton_method(:default_elasticsearch_filters) do |*args|
          if args[0]&.is_a?(::Hash) && args[0][:remove_variables]
            @default_elasticsearch_filters_without_variables ||= DefineReflectionsWithDefaultElasticsearchFilters.remove_variables_from_elasticsearch_filters(default_elasticsearch_filters)
          else
            default_elasticsearch_filters
          end
        end
      end
    end

    private

    def self.remove_variables_from_elasticsearch_filters(filters)
      case filters
      when Hash
        filters.each_with_object({}) do |(k, v), result|
          if k == 'variable'
            # don't add in result
          elsif k == 'or' && v.is_a?(Array) && v.detect{|h| h.values.first.try(:values).try(:first).try(:keys).try(:first) == 'variable'}
            # don't add in result an or that contains a variable
          elsif v.is_a?(Hash) || v.is_a?(Array)
            cleaned = remove_variables_from_elasticsearch_filters(v)
            result[k] = cleaned if cleaned.any?
          else
            result[k] = v
          end
        end
      when Array
        filters.map do |f|
          remove_variables_from_elasticsearch_filters(f)
        end.reject{|f| (f.is_a?(Hash) || f.is_a?(Array)) && f.empty? }
      else
        filters
      end
    end
  end
  prepend DefineReflectionsWithDefaultElasticsearchFilters

  module DefineReflectionsWithDefaultElasticsearchOrder
    def define_reflections
      super
      default_elasticsearch_order = self.default_elasticsearch_order
      names = [const_association_name]
      names << const_association_name_with_deleted if with_deleted?
      names.each do |name|
        reflection = self.owner_klass.const.reflect_on_association(name)
        next unless reflection
        reflection.define_singleton_method(:default_elasticsearch_order) { default_elasticsearch_order }
      end
    end
  end
  prepend DefineReflectionsWithDefaultElasticsearchOrder

  concerning :AssociationCreateDefaultForms do
    included do
      attr_accessor :skip_create_default_forms
      after_create_before_commit_schema :create_default_forms, unless: :skip_create_default_forms
      after_destroy_before_commit_schema :destroy_default_forms

      private

      def create_default_forms
        create_default_form_new
      end

      def create_default_form_new
        return unless target_klass

        form = schema.forms.create!({
          human_name_fr: "Nouveau #{target_klass.human_name_fr}",
          human_name_en: "New #{target_klass.human_name_en}",
          actions: [:new],
          mode: :input,
          klass_name: target_klass.const_absolute_name,
          target_klass_name: owner_klass.const_absolute_name,  # note: owner => target, target => source
          source_klass_name: target_klass.const_absolute_name,
          association: "#{owner_klass.const_absolute_name}.#{name}",
          default: true,
          updated_when_schema_is_changed: true,
        })

        target_klass.update_default_form(form: form, assoc: self)
      end

      def destroy_default_forms
        return unless target_klass

        schema.forms.where(
          target_klass_name: owner_klass.const_absolute_name,
          source_klass_name: target_klass.const_absolute_name,
          association_name: name,
          default: true,
        ).destroy_all
      end
    end
  end

  concerning :AssociationChangeUpdateDefaultForms do
    included do
      attr_accessor :skip_create_default_forms
      after_create_before_commit_schema :update_default_forms, unless: :skip_create_default_forms
      after_destroy_before_commit_schema :update_default_forms

      after_update_before_commit_schema :update_default_forms_elements_type, if: :type_previously_changed?

      def update_default_forms
        return unless self.is_a?(Dynamic::Schema::Association::BelongsTo)
        owner_klass.update_default_form(action: :new, mode: :input, attr: self)
        owner_klass.update_default_form(action: :edit, mode: :edit_in_place, attr: self)
        owner_klass.update_default_form(action: :show, mode: :read_only, attr: self)
        owner_klass.update_default_form(action: :submit_all, mode: :input, attr: self)
      end

      def update_default_forms_elements_type
        target_type = self.type == 'HasMany' ? 'BelongsTo' : 'HasMany'
        Dynamic::Form::Element::Association.const_get(target_type).where(
          klass_name: self.owner_klass.const_absolute_name,
          attribute_name: self.name
        ).find_each do |elem|
          elem.update!(type: "Association::#{self.type}")
        end
      end
    end
  end

  concerning :AssociationUpdateDefaultLayouts do
    included do

      attr_accessor :skip_sheet_tab_create
      after_create_before_commit_schema :update_default_layouts_create, unless: :skip_sheet_tab_create
      after_update_before_commit_schema :update_default_layouts_update
      after_destroy_before_commit_schema :update_default_layouts_destroy

      def update_default_layouts_create
        update_sheet_all_tab(:append)
        update_sheet_tabs(:create)
      end

      def update_default_layouts_destroy
        update_sheet_all_tab(:delete)
        update_sheet_tabs(:destroy)
      end

      def update_default_layouts_update
        update_sheet_tabs(:update)
      end

      def build_association_tab_attributes
        {
          component: 'Crm::Sheet::TabBar::Tab',
          component_params: build_association_tab_component_params,
          children_attributes: self.class.build_association_tab_children_attributes([self])
        }
      end

      def build_association_tab_component_params # TODO other translations
        {
          icon: self.try(:icon) || self.target_klass.try(:icon),
          name: self.name,
          association_id: self.id,
          translations: {
            fr: {title: self.human_name_fr},
            en: {title: self.human_name_en}
          },
        }
      end

      private

      def update_sheet_all_tab(action)
        return unless self.is_a?(Dynamic::Schema::Association::HasMany)
        return unless layout_edit

        sheet_all_tab = layout_edit.elements.detect do |e|
          e.component == 'Crm::Sheet::TabBar::Tab' && e.component_params['name'] == 'all'
        end
        return unless sheet_all_tab

        sheet_all_tab.children.destroy_all

        has_many_associations = self.owner_klass.associations.select do |a|
          a.class.name == 'Dynamic::Schema::Association::HasMany'
        end

        if action == :delete || action == :destroy
          has_many_associations = has_many_associations.select{|a| a.id != self.id}
        elsif !has_many_associations.detect{|a| a.id == self.id}
          has_many_associations << self
        end

        sheet_all_tab.update(children_attributes: self.class.build_association_tab_children_attributes(has_many_associations))
      end

      def update_sheet_tabs(action)
        return unless self.is_a?(Dynamic::Schema::Association::HasMany)

        case action
        when :create
          return unless layout_edit
          sheet_tab_bar = layout_edit.elements.detect do |e|
            e.component == 'Crm::Sheet::TabBar'
          end
          return unless sheet_tab_bar
          sheet_tab_bar.children.create!(build_association_tab_attributes)
        when :update
          return unless name_previously_changed? || target_klass_id_previously_changed? || human_name_previously_changed?
          Dynamic::Layout::Element
            .joins(:layout)
            .where(
              dynamic_layouts: {
                schema_id: schema.id,
                klass_name: self.owner_klass.const_absolute_name,
                default: true,
              }
            )
            .where(component: 'Crm::Sheet::TabBar::Tab')
            .where(["component_params::json->>'association_id'=?", self.id])
            .update_all(
              component_params: build_association_tab_component_params
            )
        when :destroy
          Dynamic::Layout::Element
            .joins(:layout)
            .where(
              dynamic_layouts: {
                schema_id: schema.id,
                klass_name: self.owner_klass.const_absolute_name,
                default: true,
              }
            )
            .where(component: 'Crm::Sheet::TabBar::Tab')
            .where(["component_params::json->>'association_id'=?", self.id])
            .delete_all
        end
      end

      def layout_edit
        @layout_edit ||= schema.layouts.with_action(:edit).where(
          klass_name: self.owner_klass.const_absolute_name,
          updated_when_schema_is_changed: true,
          default: true,
        ).last
      end

    end

    class_methods do

      def build_association_tab_children_attributes(associations)
        return [] unless associations.any?

        associations_ = associations.dup

        a = associations_.pop

        forms = a.schema.forms.where(
          target_klass_name: a.owner_klass.const_absolute_name,
          association_name: a.name,
        )

        associations_.each do |a|
          forms = forms.or(
            a.schema.forms.where(
              target_klass_name: a.owner_klass.const_absolute_name,
              association_name: a.name,
            )
          )
        end

        return [
          {
            component: 'Toolbar',
            component_params: {
              class: 'w-100 mt-2 mb-2',
            },
            children_attributes: [{
              component: 'Crm::Sheet::NewItemButton',
              component_params: {
                class: 'pull-right',
              },
              component_params_converter_type: 'Crm::Sheet::NewItemButton::ParamsConverter',
              children_attributes: forms.map do |f|
                {
                  component: 'Toolbar::Dropdown::Item',
                  component_params_converter_type: 'Crm::Sheet::NewItemButton::DropdownItem::ParamsConverter',
                  component_params_converter_options: {
                    form_id: f.id,
                    klass_name: f.klass_name,
                    translations: {
                      fr: { text: f.human_name_fr },
                      en: { text: f.human_name_en },
                    },
                  }
                }
              end

            }]
          },
          {
            component: 'InfiniteScroller',
            component_params: {
              class: 'container-fluid',
            },
            component_params_converter_options: {
              schema_association_ids: associations.map(&:id)
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
  end

  concerning :NamePreviouslyWas do # remove this concern after migration to rails 6.1+
    def name_previously_was
      self.previous_changes['name'].try(:first)
    end
  end

  include ::Dynamic::Schema::Base::ChangeUpdateAutocompleteFilters

  concerning :DefaultValueRecordsEditor do
    # read by the polymorphic belongs_to of the schema settings editor (frontend)
    def default_value_record_type
      default_value_record_refs.first&.dig('type')
    end

    # submitted by the HasMany element of the schema settings editor (frontend)
    def default_value_record_ids=(value)
      value = value.with_num_keys_to_array if value.is_a?(::Hash) && value.keys.all?{|k| k.match?(/\A\d+\z/) }
      self.default_value_records = value
    end
  end

end
