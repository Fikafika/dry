class Layout
  class Editor
    module Panel
      class Base < HyperComponent

        param :element, default: nil
        param :delete_promise, default: nil
        param :replace_elements_of_selected_element,  default: nil

        collect_other_params_as :other_params

        fires :change
        fires :reload

        attr_accessor :form

        render { content }

        def content
          return unless element
          DIV do
            title
            Form(
              record: record,
              class: 'container-fluid',
            ) do
              ::Form::Element::Attribute::Hash(
                attribute_name: 'component_params',
                mode: 'nested_form',
              ) do
                parameters
              end
              params_converters
            end.on(:loaded) do |form|
              @form = form
            end.on(:change) do |form|
              attrs = form.submission.params.values.first
              attrs.delete("id")
              attrs.each do |k, v|
                record.attributes[k] = v
              end
              change!
            end
          end
        end

        def title
          DIV(class: 'border-bottom mb-3 d-flex align-items-start') do
            DIV(class: 'p-2') do
              title_path
            end
            spacer
            delete_btn
          end
        end

        def title_path
          return unless element
          begin
            element.ancestors.reverse_each do |c|
              SPAN { c.component.to_s }
              chevron
            end
            SPAN { element.component.to_s }
          rescue => e
            puts e.message
          end
        end

        def parameters
        end

        def delete_btn
          A(href: '#', class: 'btn btn-light') do
            I(class: 'fas fa-trash') {}
          end.on(:click) do |event|
            event.prevent_default
            other_params[:delete_element]&.call(element)
          end
        end

        def spacer
          DIV(class: 'flex-grow-1') {}
        end

        private

        def record
          return element
        end

        def record_klass
          record&.klass_name&.safe_constantize
        end

        def chevron
          I(class: 'fas fa-chevron-right px-2'){}
        end

        def human_attribute_name
          record.klass&.human_attribute_name(record.attribute_name)
        end

        def label_parameter
          ::Form::Element::Attribute::TranslatableString(
            {
              attribute_name: 'label',
              nullify: true,
            }.merge!(
              placeholders do
                record.klass&.human_attribute_name(record.attribute_name)&.capitalize
              end
            )
          ).on(:change) do |value, form|
            puts form.submission.params.inspect
          end
        end

        def placeholders
          result = {}
          I18n.available_locales.each do |l|
            I18n.with_locale(l) do
              result["placeholder_#{l}"] = yield
            end
          end
          return result
        end

        def css_class_parameter
          ::Form::Element::Attribute::String(
            attribute_name: 'class',
          )
        end

        def params_converters
          return unless element.component
          converters = ::Layout::ParamsConverter.converters_for[element.component]
          values = converters&.map{ |x| {value: x, label: x} } || []
          return unless values.any?

          ::Form::Element::Attribute::Enum(
            attribute_name: 'component_params_converter_type',
            possible_values: values,
          )
          params_converter_parameters
        end

        def params_converter_parameters
        end

        def translated_parameter(args = {})
          Form(record: record_for_translated_parameter) do
            ::Form::Element::Attribute::TranslatableString(args).on(:change) do |value, _, _, locale|
              form.submission.write(['element', 'component_params_converter_options', 'translations', locale, args[:attribute_name]], value)
              form.change!(form)
            end
          end
        end

        track_changes [:element, :id]

        def record_for_translated_parameter
          return @record_for_translated_parameter if @record_for_translated_parameter && !element_id_changed?
          attrs = {}
          record.component_params_converter_options&.[](:translations)&.each do |locale, localized_attrs|
            localized_attrs.each do |attr, value|
              attrs["#{attr}_#{locale}"] = value
            end
          end
          @record_for_translated_parameter = HyperResource::Base.new(attrs)
          return @record_for_translated_parameter
        end

        module Associations; extend ActiveSupport::Concern

          def schema
            other_params['schema']
          end

          def schema_klass
            return unless klass_name
            name = klass_name.demodulize
            return schema.klasses.detect{|k| k.name == name}
          end

          def klass_name
            other_params[:layout]&.klass_name
          end

          def klass
            klass_name.safe_constantize
          end

          def possible_associations
            schema_klass.associations.map{|a| {value: a.id, label: a.human_name}}
          end

          def has_inverse_association?(assos_name)
            !!klass.reflect_on_association(assos_name)&.options.try(:[], :inverse_of)
          end

          def possible_inverse_associations
            schema_klass.associations.select{|a| has_inverse_association?(a.name) }.map{|a| {value: a.id, label: a.human_name}}
          end

        end

      end
    end
  end
end
