class Settings
  class Schema
    class Klasses
      class Permissions < Base

        render { content }

        after_mount do
          @target_name = request.params[:rule_id] == schema_klass.name ? nil : request.params[:rule_id]
        end

        def self.feature
          'Dynamic::Permission::Feature'
        end

        def self.resources_name
          'rules'
        end

        def self.resource_id_key
          'rule_id'
        end

        def list_page
          Stackable::Page() do
            Stackable::Toolbar() do
              Stackable::PageHeader(title: UneekPermission::Rule.model_name.human, back: back_location)
            end
            if schema_klass
              Preview(
                schema_klass: schema_klass,
                attributes: attributes,
                associations: associations,
                attachments: attachments,
                rules: rules,
              ).on(:element_selected) do |name, type|
                case type
                when 'klass'
                  @target_name = nil
                  App.history.push("#{current_location}/#{schema_klass.name}")
                when 'attr', 'assoc', 'attach'
                  @target_name = name
                  App.history.push("#{current_location}/#{name}")
                end
              end
            end
          end
        end

        after_mount do
          @target = request.params[:rule_id]
        end

        def edit_page
          Stackable::LargePage() do
            Stackable::Toolbar() do
              Stackable::PageHeader(title: edit_page_title, back: current_location)
            end
            ::Permission::Manager(
              rules: select_rules_from_target_name,
              params_for_new_record: new_record_params,
              possible_attributes_values: possible_attributes_values || [],
              enum_values_proc: Proc.new do |attr|
                enum_values_from_attr(attr)
              end,
              klass_name: request.params[:klass_id],
              schema_name: request.params[:schema_id],
            )
          end
        end

        def edit_page_title
          if schema_klass && attributes
            return schema_klass.human_name if request.params[:rule_id] == schema_klass.name
            attr = attributes.detect{|attr| attr.name == request.params[:rule_id]}
            return attr.human_name if attr
            asso = associations.detect{|asso| asso.name == request.params[:rule_id]}
            return asso.human_name if asso
          end
        end

        def select_rules_from_target_name
          target = targetted_attr
          rules.select {|r| r.attr == target}
        end

        def targetted_attr
          result = @target_name
          assoc = schema_klass.associations.detect {|a| a.name == @target_name}
          if assoc
            result += '_id'
            result += 's' if assoc.is_a?(Dynamic::Schema::Association::HasMany)
          end
          return result
        end

        def new_record_params
          return {
            klass_name: klass_name,
            attr: request.params[:rule_id] == schema_klass.name ? nil : targetted_attr,
          }
        end

        def possible_attributes_values
          observe options_for_indexed_json = schema_klass.options_for_indexed_json
          const_klass = schema_klass_name.safe_constantize
          return nil unless const_klass
          return options_for_indexed_json_to_options(const_klass, options_for_indexed_json)
        end

        def options_for_indexed_json_to_options(klass, options, prefix = '')
          return unless options
          results = []

          options[:only]&.each do |attr|
            unsupported_attribute = ::UneekPermission::Rule::DOMAIN_OPERATION_METHODS_BY_TYPE[klass.attributes.dig(attr, 'type')].nil?
            next if unsupported_attribute || attr == 'deleted_at'
            results << {
              label: klass.human_attribute_name(attr),
              value: "#{prefix}#{attr}",
            }
          end

          options[:include]&.each do |asso, asso_options|
            reflection = klass.reflect_on_association(asso)
            next unless reflection && reflection.options[:class_name]
            k = reflection.options[:class_name].safe_constantize
            results << {
              label: klass.human_attribute_name(asso),
              value: "#{prefix}#{asso}",
              options: options_for_indexed_json_to_options(k, asso_options, "#{prefix}#{asso}."),
            }
          end

          return results.sort_by{|r| r[:label]}
        end

        def enum_values_from_attr(attr)
          return [] unless attr
          attrs = attr.split('.')
          c_klass = schema_klass

          if attrs.length > 1
            attrs[0...-1].each do |a|
              trgt = c_klass.associations.detect { |assoc| assoc.name == a }
              break unless trgt&.target_klass_id
              c_klass = schema.klasses.detect { |k| k.id == trgt.target_klass_id }
            end
          end
          attribute = c_klass.attrs.detect{ |a| a.name == attrs[-1] }
          return [] unless attribute&.type == 'Enum'

          observe enum_values = Dynamic::Schema::Attribute::Enum::Value.where(
            attr_id: attribute.name,
            schema_id: request.params[:schema_id],
            klass_id: c_klass.id
          ).all
          enum_values.map { |val| { name: val.name, human_name: val.human_name } }
        end

        def klass_name
          "D::#{request.params[:schema_id].classify_permalink}::#{request.params[:klass_id].classify_permalink}"
        end

        def current_location
          "#{back_location}/#{resources_name}"
        end

        def associations
          return @associations if @associations&.any?
          @associations = schema_klass.associations
        end

        def attributes
          return @attrs if @attrs&.any?
          @attrs = schema_klass.attrs
        end

        def attachments
          return @attachments if @attachments&.any?
          @attachments = schema_klass.attachments
        end

        def rules
          @rules = []
          ::UneekPermission::Rule.where(klass_name: klass_name, schema_id: schema.id).all do |r|
            @rules = r
            mutate
          end
          return @rules
        end

        class Preview < HyperComponent
          include Router::Helpers

          param :schema_klass
          param :attributes, default: []
          param :associations, default: []
          param :attachments, default: []
          param :rules, default: []
          param :css_class, default: nil
          param :item_css_class, default: 'bg-light-yiq'

          collect_other_params_as :other_params

          fires :element_selected

          render { content }

          def content
            DIV(class: "overflow-auto list-group list-group-flush #{css_class}") do
              summarized_element(
                title: schema_klass.human_name,
                name: schema_klass.name,
                type: 'klass',
                receivers: gather_receivers,
                icon: 'window-maximize',
                css_class: "#{item_css_class} border-top-0",
              )

              attributes.each do |attr|
                summarized_element(
                  title: attr.human_name,
                  name: attr.name,
                  type: 'attr',
                  receivers: gather_receivers(attr: attr.name),
                  is_object_name: attr.id == schema_klass.name_attribute_id,
                  css_class: item_css_class,
                )
              end

              associations.each do |association|
                targetted_attr = "#{association.name}_id"
                targetted_attr += 's' if association.is_a?(Dynamic::Schema::Association::HasMany)
                summarized_element(
                  title: association.human_name,
                  name: association.name,
                  type: 'assoc',
                  receivers: gather_receivers(attr: targetted_attr),
                  icon: 'arrow-right',
                  css_class: item_css_class,
                )
              end

              attachments.each do |attachment|
                summarized_element(
                  title: attachment.human_name,
                  name: attachment.name,
                  type: 'attach',
                  receivers: gather_receivers(attr: attachment.name),
                  icon: 'arrow-right',
                  css_class: item_css_class,
                )
              end
            end
          end

          def summarized_element(title:, name:, type:, receivers:, icon: 'minus', is_object_name: false, css_class:)
            DIV(class: "list-group-item #{css_class}") do
              DIV(class: 'd-flex justify-content-between align-items-center') do
                SPAN() do
                  I(class: "fas fa-#{icon}")
                  SPAN(class: 'ml-3') do
                    title&.capitalize
                  end
                end
                if is_object_name
                  SMALL(class: 'm-0 p-0 fs-6') do
                    I18n.t('activerecord.attributes.dynamic/schema/klass.name_attribute')
                  end
                end
              end

              DIV(class: 'd-flex pt-1') do
                DIV(class: 'card flex-grow-1', style:{margin: '0 2rem'}) do
                  DIV(class: 'card-body p-2') do
                    receivers.each do |receiver|
                      I(class: "fa fa-#{receiver&.class&.icon || ''}", style:{margin: '0 0.3rem'}, title: (receiver.try(:name) || ''))
                      SPAN {receiver.try(:human_name) || receiver.try(:name)}
                    end
                  end
                end
                BUTTON(class: 'btn shadow-none', style: {cursor: 'pointer'}) do
                  I(class: 'fa fa-chevron-right')
                end.on(:click) do |event|
                  element_selected!(name, type)
                end
              end
            end
          end

          def gather_receivers(attr: nil)
            rules.select {|record| record.attr == attr }.map {|record| record.receiver}
          end

        end

      end
    end
  end
end