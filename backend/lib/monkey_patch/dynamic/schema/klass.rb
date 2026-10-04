ActiveSupport.on_load(:dynamic_schema_klass) do

  concerning :Identification do
    included do
      belongs_to :name_attribute, class_name: 'Dynamic::Schema::Attribute::Base', optional: true
      belongs_to :photo_attachment, class_name: 'Dynamic::Schema::Attachment::HasOne', optional: true
    end

    def load_attributes
      super
      load_identification_attributes
    end

    def load_identification_attributes
      n = inherited_name_attribute&.name
      const.define_singleton_method :name_attribute do
        n
      end

      p = inherited_photo_attachment&.name
      const.define_singleton_method :photo_attachment do
        p
      end
    end

    def inherited_name_attribute
      name_attribute || superklass&.inherited_name_attribute
    end

    def inherited_photo_attachment
      photo_attachment || superklass&.inherited_photo_attachment
    end

    class_methods do

      def preload_attrs_associations_attachments_and_validations(klasses)
        super
        klasses.each do |klass|
          klass.name_attribute = klass.attrs.detect{|a| a.id == klass.name_attribute_id}
          klass.photo_attachment = klass.attachments.detect{|a| a.id == klass.photo_attachment_id}
        end
      end

    end
  end

  concerning :Creator do

    def load_versioning
      version_klass = super
      return nil unless version_klass

      version_klass.belongs_to :author, foreign_key: :whodunnit, class_name: 'User', optional: true
      const.has_one :version_with_create_event, ->{ where(event: 'create') }, class_name: version_klass.name, foreign_key: :item_id
      const.has_one :_creator, through: :version_with_create_event, source: :author
      return version_klass
    end

    def version_whodunnit_column_type
      :uuid
    end

    def version_event_index?
      true
    end

  end

  concerning :Serialization do
    def load
      super
      load_serialization_methods
    end

    def includes_for_variables(variables)
      includes = {include: {}, only: Set.new}

      includes[:only] << self.name_attribute.name if self.name_attribute

      variables.each do |variable|
        current_klass = self
        current_includes = includes
        keys = variable.split('.')

        keys.each do |key|
          # skip numbers array index
          key = key[/^[^@]+/]

          if current_klass.attrs.detect{|a| a.name == key} || ['id', 'created_at', 'updated_at', 'deleted_at'].include?(key)
            current_includes[:only] << key
            break
          end

          key_sym = key.to_sym

          association_klass = current_klass.associations.detect{|a| a.name == key}

          if association_klass
            current_includes[:include][key_sym] = {include: {}, only: Set.new} unless current_includes[:include][key_sym].is_a?(Hash)
            # go deeper
            current_includes = current_includes[:include][key_sym]

            current_klass = association_klass.target_klass

            # always add name attribute
            current_includes[:only] << current_klass.name_attribute.name if current_klass.name_attribute
          elsif current_klass.attachments.detect{|a| a.name == key}
            current_includes[:include][key_sym] = Dynamic::Schema::Attachment::Base.active_storage_includes
            break
          else
            current_includes[:include].delete(key_sym)
            break
          end
        end
      end

      includes.as_json.with_indifferent_access
    end

    def load_serialization_methods
      includes_for_variables_proc = Proc.new {|variables| includes_for_variables(variables)}
      const.define_singleton_method :includes_for_variables do |variables|
        includes_for_variables_proc.call(variables)
      end
    end
  end

  concerning :SchemaCallbacks do
    included do
      def schema_in_callbacks
        @schema_in_callbacks ||= ::Dynamic::Schema.load(self.schema.name)
      end
    end
  end

  concerning :CreateDefaultForms do
    included do
      attr_accessor :skip_create_default_forms
      after_create_before_commit_schema :create_default_forms

      def create_default_forms
        return if skip_create_default_forms == true
        create_default_form_new unless skip_create_default_forms&.include?(:new)
        create_default_form_edit unless skip_create_default_forms&.include?(:edit)
        create_default_form_show_sheet unless skip_create_default_forms&.include?(:show)
        create_default_form_show_thumbnail unless skip_create_default_forms&.include?(:show)

      end

      def create_default_form_new
        form = schema.forms.create!({
          human_name_fr: "Nouveau",
          human_name_en: "New",
          actions: [:new],
          mode: :input,
          klass_name: const_absolute_name,
          default: true,
          updated_when_schema_is_changed: true,
          purpose: nil,
        })
        update_default_form(form: form)
      end

      def create_default_form_edit
        form = schema.forms.create!({
          human_name_fr: "Edition direct",
          human_name_en: "Edit in place",
          actions: [:edit],
          mode: :edit_in_place,
          klass_name: const_absolute_name,
          default: true,
          updated_when_schema_is_changed: true,
          purpose: nil,
        })
        update_default_form(form: form)
      end

      def create_default_form_show_thumbnail
        form = schema.forms.create!({
          human_name_fr: "Vignette",
          human_name_en: "List item",
          actions: [:show],
          mode: :read_only,
          klass_name: const_absolute_name,
          default: true,
          updated_when_schema_is_changed: true,
          purpose: "thumbnail",
        })
        update_default_form(form: form)
      end

      def create_default_form_show_sheet
        form = schema.forms.create!({
          human_name_fr: "Vignette pour les fiches",
          human_name_en: "List item for sheet",
          actions: [:show],
          mode: :read_only,
          klass_name: const_absolute_name,
          default: true,
          updated_when_schema_is_changed: true,
          purpose: "sheet",
        })
        update_default_form(form: form)
      end

      after_destroy_before_commit_schema :destroy_default_forms

      def destroy_default_forms
        schema.forms.where(
          klass_name: const_absolute_name,
          default: true,
        ).destroy_all
      end

      def update_default_form(options = {})

        action = options[:action]
        mode = options[:mode]
        form = options[:form]
        attr = options[:attr]

        if form
          forms = [form]
        else
          forms = schema.forms.with_action(action).where(
            default: true,
            mode: mode,
            updated_when_schema_is_changed: true,
            klass_name: const_absolute_name,
          ).all
        end

        return unless forms.any?

        forms.each do |form|

          if attr

            if attr.deleted?
              form.elements.where(
                klass_name: const_absolute_name,
                attribute_name: attr.name,
              ).destroy_all
              return
            end

            element = form.elements.where(
              klass_name: const_absolute_name,
              attribute_name: attr.name,
            ).first

            unless element
              element_attrs = dynamic_form_element_attrs(attr)
              return unless element_attrs
              element_attrs = add_compact_value(form, element_attrs)
              form.elements.create!(element_attrs)
            end

          else
            existing = Set.new
            form.elements.each do |e|
              existing << e.attribute_name
            end

            inverse_of_id = options[:assoc]&.inverse_of_id

            self.inherited_attrs_assocs_attachs.each do |a|
              next if existing.include?(a.name)
              next if inverse_of_id && a.id == inverse_of_id # eg. prevent owner
              element_attrs = dynamic_form_element_attrs(a)
              next unless element_attrs
              element_attrs = add_compact_value(form, element_attrs)
              form.elements.create!(element_attrs)
            end

          end

        end
      end

      def add_compact_value(form, element_attrs)
        element_attrs[:compact] = (form.purpose == 'thumbnail')
        element_attrs
      end

      def dynamic_form_element_attrs(attr_or_assoc_or_attachment)
        a = attr_or_assoc_or_attachment
        t = dynamic_form_element_type(a)
        return nil unless t

        return nil if t == 'Association::HasMany'
        return nil if a.try(:formula).present?

        return {
          root_klass_name: const_absolute_name,
          klass_name: const_absolute_name,
          attribute_name: a.name,
          type: t,
        }
      end

      def dynamic_form_element_type(attr_or_assoc_or_attachment) # TODO move in dynamic_form
        a = attr_or_assoc_or_attachment
        m = a.class.module_parent.name.demodulize
        if "Dynamic::Form::Element::#{m}::#{a.type}".safe_constantize
          result = "#{m}::#{a.type}"
        end
        return result
      end

    end
  end

  concerning :CreateDefaultLayouts do
    included do
      attr_accessor :skip_create_default_layouts
      after_create_before_commit_schema :create_default_layouts, unless: :skip_create_default_layouts

      def create_default_layouts
        create_default_layout_index
        create_default_layout_new
        create_default_layout_edit
        create_default_layout_show_sheet
        create_default_layout_show_thumbnail
      end

      def create_default_layout_index
        schema.layouts.create!(
          human_name_fr: "Tableau",
          human_name_en: "Table",
          actions: [:index],
          klass_name: self.const_absolute_name,
          default: true,
          purpose: nil,
          updated_when_schema_is_changed: true,
          elements_attributes: [{
            component: 'Crm::Table',
            component_params_converter_type: 'Crm::Table::ParamsConverter',
          }]
        )
      end

      def create_default_layout_new
        form = schema.forms.with_actions([:new]).where(
          default: true,
          klass_name: const_absolute_name,
          mode: :input
        ).first
        return unless form

        schema.layouts.create!({
          human_name_fr: "Nouveau",
          human_name_en: "New",
          actions: [:new],
          klass_name: const_absolute_name,
          default: true,
          updated_when_schema_is_changed: true,
          purpose: nil,
          elements_attributes: [{
            component: 'Layout::Container',
            children_attributes: [{
              component: 'Layout::Row',
              children_attributes: [{
                component: 'Layout::Column',
                component_params: {
                  class: 'p-0',
                },
                children_attributes: [{
                  component: 'Crm::Sheet::Toolbar',
                  component_params_converter_type: 'Crm::Sheet::Toolbar::ParamsConverter',
                }],
              }],
            }, {
              component: 'Layout::Row',
              children_attributes: [{
                component: 'Layout::Column',
                children_attributes: [{
                  component: 'Form',
                  component_params: {
                    dynamic_form_id: form.id,
                  },
                  component_params_converter_type: 'Crm::Sheet::FormParamsConverter',
                  children_attributes: [{
                    component: 'Form::Footer',
                  }]
                }]
              }]
            }]
          }]
        })
      end

      def create_default_layout_edit
        form = schema.forms.with_actions([:edit]).where(
          default: true,
          klass_name: const_absolute_name,
          mode: :edit_in_place,
        ).first
        return unless form

        attrs = {
          human_name_fr: "Edition",
          human_name_en: "Edit",
          actions: [:edit],
          klass_name: const_absolute_name,
          default: true,
          updated_when_schema_is_changed: true,
          purpose: nil,
          elements_attributes: [{
            component: 'Layout::Container',
            children_attributes: [{
              component: 'Layout::Row',
              children_attributes: [{
                component: 'Layout::Column',
                component_params: {
                  class: 'p-0',
                },
                children_attributes: [{
                  component: 'Crm::Sheet::Toolbar',
                  component_params_converter_type: 'Crm::Sheet::Toolbar::ParamsConverter',
                }],
              }],
            }, {
              component: 'Layout::Row',
              children_attributes: [{
                component: 'Layout::Column',
                children_attributes: [{
                  component: 'Form',
                  component_params: {
                    dynamic_form_id: form.id,
                  },
                  component_params_converter_type: 'Crm::Sheet::FormParamsConverter'
                }]
              }]
            }, {
              component: 'Layout::Row',
              children_attributes: [{
                component: 'Layout::Column',
                component_params: {
                  class: 'p-0',
                },
                children_attributes: [{
                  component: 'Crm::Sheet::TabBar',
                  children_attributes: [{
                    component: 'Crm::Sheet::TabBar::Tab',
                    component_params: {
                      icon: 'list',
                      name: 'all',
                      active: true,
                      translations: {
                        fr: {title: 'Tout'},
                        en: {title: 'All'}
                      },
                    },
                    component_params_converter_options: {
                      schema_association_ids: [],
                    },
                    children_attributes: [],
                  },
                  #{
                    #component: 'Crm::Sheet::TabBar::Tab',
                    #component_params: {
                      #icon: 'history',
                      #name: 'versions',
                      #translations: {
                        #fr: {title: 'Historique'},
                        #en: {title: 'History'},
                      #},
                    #},
                  #}
                  ]
                }]
              }]
            }]
          }]
        }

        #pp attrs

        schema.layouts.create!(attrs)
      end

      def create_default_layout_show_sheet
        form = schema.forms.with_actions([:show]).where(klass_name: const_absolute_name, default: true, mode: :read_only, purpose: 'sheet').first
        return unless form

        schema.layouts.create!({
          human_name_fr: "Vignette pour les fiches",
          human_name_en: "List item for sheet",
          actions: [:show],
          klass_name: const_absolute_name,
          default: true,
          purpose: 'sheet',
          updated_when_schema_is_changed: true,
          elements_attributes: [{
            component: 'Media',
            children_attributes: [
              {
                component: 'Media::Photo',
                component_params: {
                  icon: self.try(:icon),
                },
              }, {
                component: 'Media::Body',
                children_attributes: [{
                  component: 'Form',
                  component_params: {
                    dynamic_form_id: form.id,
                  },
                  component_params_converter_type: 'Crm::List::Item::FormParamsConverter'
                }]
              }
            ],
          }]
        })
      end

      def create_default_layout_show_thumbnail
        form = schema.forms.with_actions([:show]).where(klass_name: const_absolute_name, default: true, mode: :read_only, purpose: 'thumbnail').first
        return unless form

        schema.layouts.create!({
          human_name_fr: "Vignette",
          human_name_en: "List item",
          actions: [:show],
          klass_name: const_absolute_name,
          default: true,
          purpose: 'thumbnail',
          updated_when_schema_is_changed: true,
          elements_attributes: [{
            component: 'Media',
            children_attributes: [
              {
                component: 'Media::Body',
                children_attributes: [{
                  component: 'Form',
                  component_params: {
                    dynamic_form_id: form.id,
                  },
                  component_params_converter_type: 'Crm::List::Item::FormParamsConverter'
                }]
              }
            ],
          }]
        })
      end

      after_destroy_before_commit_schema :destroy_default_layouts

      def destroy_default_layouts
        schema.layouts.where(
          klass_name: const_absolute_name,
          default: true,
        ).destroy_all
      end

      def recreate_default_layouts # for maintenance
        destroy_default_layouts
        create_default_layouts
        associations.each(&:update_default_layouts_create)
      end

    end
  end

  concerning :UpdateDynamicMenu do
    included do

      before_validation :init_plural_human_name, if: :new_record?

      def init_plural_human_name
        I18n.available_locales.each do |l|
          next if self.send(:"plural_human_name_#{l}")
          self.send(:"plural_human_name_#{l}=",  self.send(:"human_name_#{l}")&.pluralize)
        end
      end

      after_create_before_commit_schema :update_dynamic_menus_create_items, if: :update_menu_items?
      after_update_before_commit_schema :update_dynamic_menus_update_items, if: :update_menu_items?
      after_destroy_before_commit_schema :update_dynamic_menus_destroy_items, if: :update_menu_items?

      def dynamic_menu_item_attributes(include_translations = true)
        result = {
          link: "/crm/#{self.schema.name.underscore}/table/#{self.route_key}/last_search",
          icon: self.icon,
        }
        if include_translations
          I18n.available_locales.map do |l|
            result["label_#{l}"] = self.send(:"plural_human_name_#{l}")
          end
        end
        return result
      end

      attr_accessor :update_menu_items
      def update_menu_items?
        @update_menu_items != false
      end

      private

      def update_dynamic_menus_create_items
        menu_klass = dynamic_menu_klass
        return unless menu_klass

        attrs = dynamic_menu_item_attributes(false).merge!(position: 99999)
        translated_attrs = I18n.available_locales.map do |l|
          { label: self.send(:"plural_human_name_#{l}"), locale: l }
        end

        menu_klass.where(name: 'crm').find_in_batches do |b|
          batch = []
          batch_translations = []

          b.each do |m|
            batch << attrs.merge(menu_id: m.id)
          end
          item_ids = menu_klass::Item.import(batch).ids
          item_ids.each do |id|
            batch_translations.concat(translated_attrs.map{|a| a.merge(owner_id: id) })
          end

          menu_klass::Item::Translation.import(batch_translations)
        end

        menu_klass.where(name: 'crm').touch_all
      end

      def dynamic_menu_klass
        "D::#{self.schema.name}::R::Menu".safe_constantize
      end

      def update_dynamic_menus_destroy_items
        menu_klass = dynamic_menu_klass
        return unless menu_klass

        item_ids = dynamic_menu_items.select('id').all.map(&:id)
        return unless item_ids.any?

        menu_klass::Item.where(id: item_ids).destroy_all
        menu_klass::Item::Translation.where(owner_id: item_ids).destroy_all
        menu_klass.where(name: 'crm').touch_all
      end

      def dynamic_menu_items
        return dynamic_menu_klass::Item.where('link ~ ?', regexp_for_dynamic_menu_item_link)
      end

      def update_dynamic_menus_update_items
        return if options_for_indexed_json_previously_changed? # why ?
        return unless self.route_key_previously_changed? || self.icon_previously_changed? || self.plural_human_name_previously_changed?

        menu_klass = dynamic_menu_klass
        return unless menu_klass

        updates = []

        if self.route_key_previously_changed?
          replacement = "/crm/#{self.schema.name.underscore}/\\1/#{self.route_key}\\2"
          updates << "link = regexp_replace(link, '#{regexp_for_dynamic_menu_item_link}', '#{replacement}')"
        end

        if self.icon_previously_changed?
          previous_icon = self.previous_changes['icon'].first
          if previous_icon.present?
            updates << "icon = CASE WHEN icon = '#{previous_icon}' THEN '#{icon}' ELSE '#{previous_icon}' END"
          else
            updates << "icon = '#{self.icon}'"
          end
        end

        if self.plural_human_name_previously_changed?
          ids = dynamic_menu_items.select(:id).all.map(&:id)
        end

        if updates.any?
          dynamic_menu_items.update_all(updates.join(', '))
        end

        if self.plural_human_name_previously_changed?
          k = menu_klass::Item::Translation
          scope = k.where(owner_id: ids)

          case_when = []
          i = 0

          c = self.class.connection

          self.translations.each do |t|
            next unless self.previous_changes["plural_human_name_#{t.locale}"]
            p = self.previous_changes["plural_human_name_#{t.locale}"].try(:[], 0)

            # assume translations still contains previous plural_human_name
            if i == 0
              scope = scope.where(locale: t.locale, label: p)
            else
              scope = scope.or(k.where(owner_id: ids, locale: t.locale, label: p))
            end
            case_when << "WHEN locale = #{c.quote(t.locale)} THEN #{c.quote(self.send(:"plural_human_name_#{t.locale}"))}"
            i += 1
          end

          scope.update_all("label = CASE #{case_when.join(' ')} END") if case_when.any?
        end
        menu_klass.where(name: 'crm').touch_all
      end

      def regexp_for_dynamic_menu_item_link
        n = self.route_key_previously_changed? ? self.previous_changes['route_key'].first : self.route_key
        reg = "\/crm\/#{self.schema.name.underscore}\/([^/]+)\/#{n}([\/|$]+)"
      end

    end
  end

  concerning :NormalizeAll do

    def normalize_all_records_asynchronously
      Dynamic::Record::Normalization::Worker.perform_async(
        ["#{self.const_absolute_name}-*"],
        {'with_deleted' => true}
      )
    end

  end

  concerning :Permission do

    def options_for_indexed_json_for_current_user
      if User.current&.admin?(schema_id)
        options_for_indexed_json
      else
        permitted_options_for_indexed_json(User.current)
      end
    end

  end

  concerning :CountRecords do

    def count_records
      self.schema.load unless self.schema.loaded?
      return self.const.count
    end

  end

end
