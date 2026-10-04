# backtick_javascript: true
class Settings

  class Schema

    class Associations < Klasses::Base

      render { content }

      def klass
        ::Dynamic::Schema::Association::Base
      end

      def self.includes_for_show
        result = super
        result.deep_merge!({
          include: {
            default_value_record_type: 1,
            default_value_record: 1,
            default_value_records: 1,
          },
        })
        return result
      end

      def new_record
        klass.new({
          schema_id: match.params['schema_id'],
          owner_klass_id: match.params['klass_id'],
          target_klass_id: match.params['target_klass_id'] || schema_klasses&.first&.id,
          type: 'BelongsTo',
        })
      end

      def schema_klasses
        observe Dynamic::Schema::Klass.order(human_name: :asc).where({
          schema_id: match.params['schema_id'],
        }).page(1).per(1000).all # TODO assume there is less than 1000 classes
      end

      def edit_panel
        EditPanel(record: current_model, schema_klasses: schema_klasses, path: "#{index_location}/:id", schema: schema, back_location: back_location)
      end

      class EditPanel < ::Settings::Schema::EditPanel
        include UrlHelper

        param :schema_klasses
        param :back_location

        render { content }

        def form
          Form(record: record) do
            if mandatory_data_loaded?
              Form::Element::Attribute::TranslatableString(
                attribute_name: 'human_name',
                errors_from: 'name',
                help: record.new_record? ? '' : I18n.t('activerecord.defaults.attributes.variable_name_text', variable_name: record.name),
                auto_focus: true,
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'type',
              ) do
                ::Dynamic::Schema::Association::Base.subclasses.each do |klass|
                  OPTION(value: klass.name.demodulize) do
                    klass.model_name.human
                  end
                end
              end
              if record.target_klass_id
                target_klass_input_with_redirect
              else
                target_klass_input
              end
              Form::Element::Attribute::Enum(
                attribute_name: 'inverse_of_id',
              ) do
                OPTION(value: '')
                inverse_associations_different_from_record&.each do |association|
                  OPTION(value: association.id) do
                    association.human_name
                  end
                end
              end
              Form::Element::Attribute::Boolean(
                editor: 'hidden',
                attribute_name: 'update_associations_from_inverses',
                default_value: '1',
              )
              Form::Element::Attribute::Boolean(
                attribute_name: 'dependent_destroy'
              )
              Form::Element::Layout::Condition(type: 'BelongsTo') do
                Form::Element::Attribute::Boolean(
                  attribute_name: 'touch_target'
                )
              end
              Form::Element::Attribute::Enum(
                attribute_name: 'through_id',
              ) do
                OPTION(value: '')
                owner_klass_associations_different_from_record&.each do |association|
                  OPTION(value: association.id) do
                    association.human_name
                  end
                end
              end
              default_filters_input
              default_order_input
              if schema.has_feature_enabled?('Dynamic::Formula::Feature')
                Formula(
                  attribute_name: 'formula',
                  klass_id_attr: 'owner_klass_id',
                  schema: schema,
                  height: '300px',
                )
              end
              default_value_input
              comment
            end
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def default_value_input
          target_klass = schema.klasses_by_id[@target_klass_id || record.target_klass_id]&.const
          label = I18n.t('activerecord.attributes.dynamic/schema/association/base.default_value')
          unless target_klass
            DIV(class: 'row form-group') do
              LABEL(class: 'col-md-3 control-label') { label }
              DIV(class: 'col-md-9') do
                SPAN(class: 'text-muted') { I18n.t('settings.klasses.associations.default_value_no_target') }
              end
            end
            return
          end
          Form::Element::Layout::Condition(type: 'BelongsTo') do
            Form::Element::Association::BelongsTo(
              key: "default-value-record-#{target_klass.name}",
              attribute_name: 'default_value_record',
              label: label,
              target_klass: target_klass,
              target_klass_url: target_klass.collection_path,
              polymorphic: true,
            )
          end
          Form::Element::Layout::Condition(type: 'HasMany') do
            Form::Element::Association::HasMany(
              key: "default-value-records-#{target_klass.name}",
              attribute_name: 'default_value_record_ids',
              label: label,
              target_klass: target_klass,
              target_klass_url: target_klass.collection_path,
              polymorphic: true,
            )
          end
        end

        def target_klass_input_with_redirect
          Form::Element::Layout::Row() do
            Form::Element::Layout::Column(col_size: 'col-9') do
              target_klass_input(
                {
                  label_col_size: 'col-md-4',
                  input_col_size: 'col-md-8'
                }
              )
            end
            Form::Element::Layout::Column(col_size: 'col-1') do
              klass = schema.klasses_by_id[@target_klass_id || record.target_klass_id]
              if klass
                A(href: target_klass_url(klass), class: 'btn btn-light', target: '_blank', 'data-toggle': 'tooltip', title: I18n.t('settings.klasses.associations.back_to_klass')) do
                  I(class: 'fa fa-window-maximize')
                end
              end
            end
          end
        end

        def default_filters_input
          target_klass = schema.klasses_by_id[@target_klass_id || record.target_klass_id]
          return unless target_klass
          owner_klass = schema.klasses_by_id[record.klass_id || record.owner_klass_id]
          DefaultFilters(
            key: "default-filters-#{record.id}-#{target_klass.id}",
            attribute_name: 'default_elasticsearch_filters',
            klass: target_klass.const,
            root_klass: owner_klass&.const,
          )
        end

        def default_order_input
          target_klass = schema.klasses_by_id[@target_klass_id || record.target_klass_id]
          return unless target_klass
          DefaultOrder(
            key: "default-order-#{record.id}-#{target_klass.id}",
            attribute_name: 'default_elasticsearch_order',
            klass: target_klass.const,
            root_klass: target_klass.const,
          )
        end

        def target_klass_input(options = {})
          Form::Element::Attribute::Enum(
            options.merge(attribute_name: 'target_klass_id')
          ) do
            OPTION(value: '')
            schema_klasses&.each do |klass|
              OPTION(value: klass.id) do
                klass.human_name
              end
            end
          end.on(:change) do |value, form|
            @target_klass_id = value
            form.submission.write(['association', 'inverse_of_id'], '') if value.blank?
            record.attributes.merge!(form.submission.params["association"])
            mutate
            form.enable
          end
        end

        def mandatory_data_loaded?
          observe schema_klasses
          observe inverse_associations
          observe owner_klass_associations
          return schema_klasses.loaded? && (inverse_klass_id.blank? || inverse_associations.try(:loaded?)) && (record.through_id.blank? || owner_klass_associations.try(:loaded?))
        end

        def inverse_associations
          return [] unless inverse_klass_id.present?
          Dynamic::Schema::Association::Base.where({
            schema_id: record.schema_id,
            klass_id: inverse_klass_id,
            target_klass_id: [record.owner_klass_id, nil]
          }).limit(1000).all
        end

        def inverse_klass_id
          @target_klass_id || record.target_klass_id
        end

        def inverse_associations_different_from_record
          inverse_associations&.select{|a| a.id != record&.id}
        end

        def owner_klass_associations
          Dynamic::Schema::Association::Base.where({
            schema_id: record.schema_id,
            klass_id: record.klass_id || record.owner_klass_id,
          }).limit(1000).all
        end

        def owner_klass_associations_different_from_record
          owner_klass_associations.select{|a| a.id != record&.id}
        end

        def footer
          form_footer
        end

        def target_klass_url(klass)
          return interpolate_path("/crm/:schema_id/settings/klasses/:klass", {
            schema_id: request.params[:schema_id],
            klass: klass.name.underscore
          })
        end
      end

      class CollectionPage < ::Settings::CollectionPage
        include ::Settings::Schema::Klasses::Base::RecomputeFormulaMenuItem
        include ::Settings::Schema::Klasses::Base::ItemIconAssigner

        def action_menu_items
          item_recompute_formula
          item_delete
        end

        def model_to_item(model)
          item = super(model)
          return item unless item
          target_klass = find_target_klass(model)
          item[:subtitle] = target_klass&.human_name
          inverse_association = find_inverse_association(model)
          if inverse_association
            tooltip = "#{I18n.t('activerecord.attributes.dynamic/schema/association/base.inverse_of_id')} #{inverse_association.human_name.capitalize}"
            icon = { icon: 'fa fa-right-left', tooltip: tooltip }
            item[:icons] ||= []
            item[:icons] << icon
          end
          attach_icons_to_item(model, item)
        end

        private

        def find_target_klass(model)
          return unless model.target_klass_id
          others[:schema]&.klasses_by_id&.[](model.target_klass_id)
        end

        def find_inverse_association(model)
          return unless model.inverse_of_id
          others[:schema]&.associations_by_id&.[](model.inverse_of_id)
        end
      end

    end

  end

end
