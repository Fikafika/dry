class Settings

  class Schema

    class Klasses < Base

      render { content }

      def klass
        ::Dynamic::Schema::Klass
      end

      def self.child_klasses
        {
          ::Dynamic::Schema::Attribute::Base => true,
          ::Dynamic::Schema::Association::Base => true,
          ::Dynamic::Schema::Attachment::Base => true,
          ::Dynamic::Schema::Validation::Base => true,
          ::Dynamic::Form => true,
          ::Dynamic::Layout => true,
          ::Dynamic::DocGen::Template => true,
          ::Settings::Schema::MailRules => true,
          ::Settings::Schema::Indexing => false,
          ::Dynamic::Schema::Cascade::Base => true,
          ::Dynamic::Knewsletter => true,
          ::Dynamic::EmailOrder::Base => true,
          ::UneekPermission::Rule => true,
          ::Settings::Schema::ApplicableAmountRules => true,
        }
      end

      def self.includes_for_all
        { include: { translations: 1 } }
      end

      def self.includes_for_show
        {
          include: {
            translations: 1,
            name_attribute: {
              include: {
                translations: 1
              },
            },
            superklass: 1,
            photo_attachment: {
              include: {
                translations: 1
              },
            },
            attrs: {
              only: ['id', 'name', 'type'],
              include: {
                translations: 1,
              },
            },
            attachments: {
              only: ['id', 'name', 'type'],
              include: {
                translations: 1,
              },
            },
            associations: {
              only: ['id', 'name', 'type', 'owner_klass_id', 'target_klass_id'],
              include: {
                translations: 1,
              },
            },
            cascades: {
              except: [ 'created_at', 'updated_at'],
            },
            schema: {
              only: [ 'id', 'name']
            }
          }
        }
      end

      def self.children_items(schema, record)
        child_items = []

        if record&.id && schema&.klasses&.any?{|k| k.superklass_id == record.id}
          child_items << {
            id: Subklasses.resources_name,
            icon: Subklasses.icon,
            title: I18n.t('settings.klasses.subklasses'),
          }
        end

        child_klasses.each do |a, plural|
          next if schema && a.feature && !schema.has_feature_enabled?(a.feature)

          child_items << {
            id: resources_name(a, plural),
            icon: a.icon,
            title: a.model_name.human(count: (plural ? 2 : 1)),
            disabled: a.try(:disabled?, record, schema)
          }
        end

        if schema&.has_feature_enabled?('Dynamic::Copy::Feature')
          child_items << {
            id: ::Settings::Schema::Klasses::CopyMappings.resources_name,
            icon: 'right-left',
            title: I18n.t('settings.klasses.copy_mappings'),
          }
        end

        child_items << {
          icon: 'table',
          title: I18n.t('settings.klasses.access_table'),
          path: "/crm/#{request.params['schema_id']}/table/#{record.route_key}/last_search",
          right_icon: 'external-link-alt',
          external_link: true,
        }

        child_items
      end

      def list_page
        CollectionPage(
          klass: klass,
          resource_id_key: resource_id_key,
          path_prefix: path_prefix,
          location: index_location,
          scope_for_all: scope_for_all,
          includes_for_all: includes_for_all,
          editable: editable?,
          schema: schema,
        )
      end


      class CollectionPage < ::Settings::Schema::CollectionPage

        render { content }

        before_update do
          @klasses_by_id = nil
          @klass_ids_with_subklasses = nil
        end

        def model_to_item(model)
          return nil unless model
          item = {
            id: model.class.api_id(model) + location_suffix,
            icon: model.try(:icon) || model.class.try(:icon) || default_icon,
            title: item_title(model),
          }
          if klass_ids_with_subklasses.include?(model.id)
            item[:icons] = [{
              icon: "fa fa-#{Subklasses.icon}",
              tooltip: I18n.t('settings.klasses.has_subklasses')
            }]
          end
          key = model.try(:name)
          if @counts_loading
            item[:count_loading] = true
          elsif (count_data = @counts&.[](key))
            if count_data.is_a?(Hash) && count_data[:error]
              item[:icons] = (item[:icons] || []) + [{
                icon: 'fa fa-exclamation-triangle text-warning',
                tooltip: count_data[:message]
              }]
            else
              item[:count] = count_data
            end
          end
          item
        end

        def item_title(model)
          title = model.try(:human_name) || model.try(:name)
          superklass = klasses_by_id[model.superklass_id]
          superklass ? "#{title} (#{superklass.human_name})" : title
        end

        def klasses_by_id
          @klasses_by_id ||= models.to_a.each_with_object({}){|m, r| r[m.id] = m }
        end

        def klass_ids_with_subklasses
          @klass_ids_with_subklasses ||= models.map(&:superklass_id).compact.uniq
        end

        def fetch_counts
          return if @counts_loading
          @counts_loading = true
          @counts = nil
          mutate
          url = "#{ENV['APP_PATH_PREFIX']}/api/dynamic/schemas/#{schema.name.underscore}/count_records.json"
          HTTP.get(url)
            .then do |response|
              @counts = response.json
              @counts_loading = false
              mutate
            end
            .fail do |error|
              @counts_loading = false
              @counts = {}
              mutate
            end
        end

        def action_menu_items
          super
          count_button
        end


        private


        def count_button
          return unless editable
          BUTTON(
            class: 'dropdown-item btn btn-link text-left',
            type: 'button',
            disabled: @counts_loading
          ) do
            I18n.t('settings.klasses.show_counts')
          end.on(:click) do |event|
            event.prevent_default
            fetch_counts
          end
        end
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
          Form(record: record) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              errors_from: 'name',
              help: record.new_record? ? '' : I18n.t('activerecord.attributes.dynamic/schema/klass.technical_name_text', technical_name: record.const_absolute_name),
              auto_focus: true,
            )
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'plural_human_name',
              errors_from: 'route_key',
            )
            Form::Element::Association::BelongsTo(
              attribute_name: 'superklass_id',
              disabled: record.persisted?
            )
            Form::Element::Attribute::Icon(
              attribute_name: 'icon',
              placeholder_icon: 'table'
            )
            name_attribute_types = ['String', 'TranslatableString']
            Form::Element::Association::BelongsTo(
              attribute_name: 'name_attribute_id',
              target_klass_url: Dynamic::Schema::Attribute::Base.collection_path({schema_id: request.params['schema_id'], klass_id: request.params['klass_id'], where: {type: name_attribute_types}}),
              target_klass: Dynamic::Schema::Attribute::Base,
              disabled: record.new_record? || !record.attrs.detect{|a| name_attribute_types.include?(a.type)},
            )
            Form::Element::Association::BelongsTo(
              attribute_name: 'photo_attachment_id',
              target_klass_url: Dynamic::Schema::Attachment::HasOne.collection_path({schema_id: request.params['schema_id'], klass_id: request.params['klass_id'], where: {type: 'HasOne'}}),
              target_klass: Dynamic::Schema::Attachment::HasOne,
              disabled: record.new_record? || !record.attachments.detect{|a| a.type == 'HasOne'},
            )
            Form::Element::Attribute::Enum(
              attribute_name: 'table_profile',
              default_value: 'medium',
              help: table_profile_help,
              help_position: 'icon',
              disabled: !record.new_record?,
            ).on(:change) do
              mutate
            end
            comment
          end.on(:success) do
            App.history.push(record_location)
          end
          children_list
        end

        def attrs_for_name
          record.attrs.select{|a| a.type == 'String'}
        end

        def attrs_for_photo
          record.attachments.select{|a| a.type == 'HasOne'}
        end

        def footer
          form_footer
        end

        def table_profile_help
          r = []
          p = record&.new_record? ? Form.current&.submission&.read(['klass', 'table_profile']) : record&.table_profile
          Dynamic::Schema::Klass::TABLE_PROFILE[p]&.each do |k, v|
            n = Dynamic::Schema::Attribute.const_get(k)&.model_name.human
            r << %Q[#{n} : #{v[:count]} #{I18n.t('settings.klasses.attributes.available_index_count', count: v[:indexed])}]
          end
          r =  r.join('<br/>')
          return r
        end
      end
    end
  end
end
