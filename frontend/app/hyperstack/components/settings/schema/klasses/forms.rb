class Settings

  class Schema

    class Forms < Klasses::Base

      render { content }

      def content
        if request.params[:action] == 'edit'
          layout do
            Editor()
          end
        elsif request.params[:action] == 'integrate'
          layout do
            Integrator()
          end
        else
          super
        end
      end

      def klass
        ::Dynamic::Form
      end

      def new_record
        klass.new(
          schema_id: match.params['schema_id'],
          klass_id: match.params['klass_id'],
          klass_name: schema_klass_name,
        )
      end

      def scope_for_all
        super.merge(klass_name: schema_klass_name)
      end

      def self.includes_for_show
        result = super
        result.deep_merge!({
          include: {
            theme: {
              only: [:id, :name, :human_name],
            },
          }
        })
        return result
      end

      def self.children_items(schema, record)
        result = [
          {
            id: 'edit',
            icon: 'paint-brush',
            title: I18n.t('shared.edit'),
          },
          {
            id: 'cascades',
            icon: I18n.t('icons.models.dynamic/schema/cascade/base'),
            title: ::Dynamic::Cascade.model_name.human(count: 2),
          },
          {
            id: 'integrate',
            icon: I18n.t('icons.apps.code'),
            title: I18n.t('crm.form_integrator.embedded'),
          },
          {
            id: 'permissions',
            icon: 'user-lock',
            title: UneekPermission::Rule.model_name.human
          },
        ]
        if record
          result << {
            path: "/crm/#{request.params['schema_id']}/forms/#{record.id}",
            icon: 'list',
            title: I18n.t('settings.schema.forms.goto_form'),
            right_icon: 'external-link-alt',
            external_link: true,
          }
        end
        return result
      end

      class CollectionPage < ::Settings::Schema::CollectionPage

        def model_to_item(model)
          i = super
          if i && model
            s = subtitle(model)
            i[:subtitle] = s if s
          end
          return i
        end

        def subtitle(model)
          return unless schema&.loaded?
          k = schema.klasses_by_const_absolute_name[model.association_klass_name || model.source_klass_name]
          unless k
            # puts model.attributes
          end
          return unless k
          assoc = k.attr_attachment_or_association(model.association_name)
          return k.human_name.capitalize unless assoc
          return "#{k.human_name.capitalize} > #{assoc.human_name.capitalize}"
        end

        def action_menu_items
          item_duplicate
          super
        end

        def item_duplicate
          A(href: '#', class: 'dropdown-item text-capitalize-first-letter') do
            I18n.t('shared.duplicate')
          end.on(:click) do |event|
            event.prevent_default
            unless current_model.nil?
              current_model.duplicate.then do |response|
                if response[:success]
                  models.try(:stale!)
                  App.history.replace(location_after_duplicate(response[:id]))
                else
                  Modal.confirm(
                    title: I18n.t('shared.error'),
                    text: I18n.t('shared.error_messages'),
                    cancelClass:'d-none',
                    commit: 'Ok'
                  ){}
                end
              end
            end
          end
        end

        def location_after_duplicate(id)
          [location, id].join('/')
        end
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
          Form(record: record) do
            Form::Element::Attribute::String(
              attribute_name: 'klass_name',
              editor: 'hidden',
            )
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              auto_focus: true,
            )
            Form::Element::Attribute::MultipleEnum(
              attribute_name: 'actions',
            ).on(:change) do |value|
              @available_modes = record.class.available_modes(value).map do |k|
                {value: k, label: record.class.human_attribute_value(:mode, k)}
              end
              mutate # for reload mode list
            end
            Form::Element::Attribute::Enum(
              attribute_name: 'association',
              possible_values: possible_associations,
            )
            Form::Element::Attribute::Enum(
              attribute_name: 'mode',
              possible_values: @available_modes,
              accept_empty_value: false,
            )
            Form::Element::Association::BelongsTo(
              attribute_name: 'theme_id',
            )
            Form::Element::Attribute::Boolean(
              attribute_name: 'evaluate_access_with_formula',
            )
            Form::Element::Layout::Condition(
              evaluate_access_with_formula: false
            ) do
              Form::Element::Attribute::DateTime(
                attribute_name: 'start_date',
              )
              Form::Element::Attribute::TranslatableText(
                attribute_name: 'text_before_start_date',
              )
              Form::Element::Attribute::DateTime(
                attribute_name: 'end_date',
              )
              Form::Element::Attribute::TranslatableText(
                attribute_name: 'text_after_end_date',
              )
            end

            Form::Element::Layout::Condition(
              evaluate_access_with_formula: true
            ) do
              Formula(
                attribute_name: 'access_formula',
                klass_id_attr: 'klass_name',
                schema: schema,
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'access_formula_record_type',
                possible_values: possible_record_types
              ).on(:change) do |value|
                record.access_formula_record_type = value
                record.access_formula_record_id = nil
                reset_and_enable_form
                mutate
              end
              Form::Element::Association::BelongsTo(
                attribute_name: 'access_formula_record_id',
                target_klass: record.access_formula_record_type&.safe_constantize,
                disabled: !record.access_formula_record_type.present?,
                key: "access_formula_record_id_#{record.access_formula_record_type}" #for refresh select after update table
              )
            end

            Form::Element::Attribute::String(
              attribute_name: 'final_redirect_url',
            )
            Form::Element::Attribute::Boolean(
              attribute_name: 'async_submission',
            )
            Form::Element::Attribute::Boolean(
              attribute_name: 'auto_submission',
            )

            Form::Element::Attribute::Text(
              attribute_name: 'on_load_script',
              editor: 'textarea',
            )

            children_list
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def reset_and_enable_form
          if Form.current && Form.current.respond_to?(:reset_without_mutate)
            values_data_store = Form.current.submission.values.except(["form", "access_formula_record_id"])
            Form.current.reset_without_mutate
            Form.current.submission.values.merge!(values_data_store)
          end
          Form.current.enable if Form.current
        end

        def possible_record_types
          (schema&.loaded? ? schema.klasses : []).map do |klass|
            { value: klass.const_absolute_name, label: klass.human_name }
          end
        end

        def possible_associations
          return [] unless schema&.loaded?
          return @possible_associations[record.klass_name] if @possible_associations&.has_key?(record.klass_name)

          @possible_associations ||= {}

          result = schema.associations.select do |a|
            a.target_klass && a.target_klass.const_absolute_name == record.klass_name
          end.map do |a|
            {
              value: "#{a.owner_klass.const_absolute_name}.#{a.name}",
              label: "#{a.owner_klass.human_name} > #{a.human_name}"
            }
          end
          @possible_associations[record.klass_name] = result

          return result
        end

        def footer
          form_footer
        end

      end

    end

  end

end
