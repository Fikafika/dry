# backtick_javascript: true
require 'components/form/element/association/base'
require 'components/form/element/tom_select'

class Crm
  module Filters
    module Input
      def self.klass_from_type(type)
        "Crm::Filters::Input::#{type}".safe_constantize || ::Crm::Filters::Input::Base
      end

      class Base < HyperComponent

        param :value
        param :column
        param :operator, default: nil
        param :auto_default_value, default: true
        param :enable_default_filters, default: true
        param :remove_variables_from_default_filters, default: true

        fires :change

        render do
          INPUT(type: "text", class: "form-control", value: value) do
          end.on(:change) do |event|
            change!(event.target.value)
          end.on(:click) do |event|
            event.target.select
          end
        end

      end

      module Attribute
        class Base < ::Crm::Filters::Input::Base; end

        class Number < Base

          render do
            INPUT(type: "number", class: "form-control", value: value) do
            end.on(:change) do |event|
              change!(event.target.value)
            end.on(:click) do |event|
              event.target.select
            end
          end

        end

        class Float < Number
        end

        class Integer < Number
        end

        class Enum < Base

          render do
            next unless column&.mapping
            DIV(class:"dropdown flex-grow-1") do
              BUTTON(class: "btn input-group-text dropdown-toggle w-100", type: "button", "data-toggle": "dropdown", style: {"minWidth": "160px"}) do
                column.mapping[value] || I18n.t("crm.enum.select")
              end
              DIV(class: "dropdown-menu") do
                column.mapping.each do |val, label|
                  next if val.is_a?(Integer)
                  A(class:"dropdown-item", href: "#") do
                    label
                  end.on(:click) do |event|
                    event.prevent_default
                    change!(val.to_s) # convert to string because false become nil
                  end
                end
              end
            end
          end

        end

        class Boolean < Enum; end

        class DateTime < Base

          render do
            case operator
            when 'date_equal', 'date_not_equal'
              Date(
                value: value,
                column: column,
              ).on(:change) do |value|
                change!(value)
              end
            when 'ago', 'since', 'until'
              Ago(
                value: value,
                column: column,
              ).on(:change) do |value|
                change!(value)
              end
            else
              INPUT(
                class: 'form-control flex-grow-1',
                value: moment_value,
                type: 'datetime-local',
                step: 1,
              ).on(:change) do |event|
                value = event.target.value
                change!(value)
              end
            end
          end

          def moment_value
            return nil if !auto_default_value && value.blank?
            v = `moment(#{value}).format(moment.HTML5_FMT.DATETIME_LOCAL_SECONDS)`
            v == 'Invalid date' ? nil : v
          end

        end

        class Date < Base

          render do
            case operator
            when 'ago', 'since', 'until'
              Ago(
                value: value,
                column: column,
                units: [
                  'days',
                  'months',
                  'years',
                ],
              ).on(:change) do |value|
                change!(value)
              end
            else
              INPUT(
                class: 'form-control flex-grow-1',
                value: moment_value,
                type: 'date',
              ).on(:change) do |event|
                value = event.target.value
                change!(value)
              end
            end
          end

          def moment_value
            return nil if !auto_default_value && value.blank?
            v = `moment(#{value}).format('YYYY-MM-DD')`
            v == 'Invalid date' ? nil : v
          end

        end

        class TimeOfDay < Base
          render do
            INPUT(
              class: 'form-control flex-grow-1',
              value: value,
              type: 'time',
              step: 1,
            ).on(:change) do |event|
              value = event.target.value
              change!(value)
            end
          end
        end

        class Ago < Base
          collect_other_params_as :others

          render do
            INPUT(type:"text", class: "form-control", value: input_value) do
            end.on(:change) do |evt|
              @input_value = evt.target.value.to_i
              change!(combined_value)
              mutate
            end
            SELECT(class: 'form-control', value: unit) do
              units.each do |v|
                OPTION(value: v) do
                  I18n.t("datetime.#{v}")
                end
              end
            end.on(:change) do |event|
              @unit = event.target.value
              change!(combined_value)
              mutate
            end
          end

          def units
            others[:units] || [
              'seconds',
              'minutes',
              'hours',
              'days',
              'months',
              'years',
            ]
          end

          def input_value
            return @input_value if @input_value
            if value.is_a?(Array)
              @input_value = value[0]
            end
            @input_value
          end

          def combined_value
            return nil unless input_value.present?
            [input_value, unit]
          end

          def unit
            return @unit if @unit
            if value.is_a?(Array)
              @unit = value[1]
            end
            @unit ||= default_unit
            return @unit
          end

          def default_unit
            others[:default_unit] || units.first
          end
        end

        class Type < Base

          render do
            next unless column&.klass

            DIV(class:"dropdown flex-grow-1") do
              BUTTON(class: "btn input-group-text dropdown-toggle w-100", type: "button", "data-toggle": "dropdown", style: {"minWidth": "160px"}) do
                value&.safe_constantize&.model_name&.human || I18n.t("crm.enum.select")
              end
              DIV(class: "dropdown-menu") do
                ([column.klass] + column.klass.descendants).each do |k|
                  A(class:"dropdown-item", href: "#") do
                    k.model_name.human
                  end.on(:click) do |event|
                    event.prevent_default
                    change!(k.name)
                  end
                end
              end
            end

          end

        end

      end

      module Association
        class Base < ::Crm::Filters::Input::Base
          include ::Form::Element::TomSelect

          before_new_params do |next_props|
            if !use_tom_select?(next_props[:operator]) && tom_select_initialized?
              finish_tom_select_events
            end
          end

          render do
            case operator
            when 'contains_name', 'not_contains_name'
              render_name_input
            else
              render_tom_select
            end
          end

          def render_tom_select
            select_args = {
              multiple: false,
              class: 'form-control',
              placeholder: I18n.t('shared.select'),
            }
            SELECT(select_args) do
              if selected_value
                OPTION(value: selected_value[:value]) do
                  selected_value[:label]
                end
              end
            end
          end

          def render_name_input
            v = value.is_a?(::Array) ? value[1] : nil
            INPUT(class:'form-control', type: 'text', value: v).on(:change) do |event|
              change!([column.target_klass&.name_attribute || 'polymorphic_name', event.target.value])
            end
          end

          def use_tom_select?(op = operator) # redefined
            !['contains_name', 'not_contains_name'].include?(op)
          end

          def tom_select_options
            @tom_select_options ||= Form::Element::Association::Base.tom_select_options(target_klass, target_klass_search_url)
          end

          def select_element # redefined from TomSelect
            self.jq_node
          end

          def record # for TomSelect
            @record
          end

          def form # for TomSelect
          end

          def change_value(value)
            value = value.first if value.is_a?(::Array)
            change!(value)
          end

          def record_is_invalid_changed? # for TomSelect
            false
          end

          def must_update_tom_select_values?
            result = @record&.loaded? != @record_was_loaded
            @record_was_loaded = @record&.loaded?
            return result
          end

          def finish_tom_select_events
            super
            @tom_select_options = nil
          end

          def must_destroy_tom_select?
            result = @previous_column_name.nil? ? false : (@previous_column_name != column.name)
            @previous_column_name = column.name
            return result
          end

          def target_klass
            column.target_klass
          end

          def target_klass_url
            target_klass&.collection_path
          end

          def target_klass_search_url
            url = target_klass_url
            return unless url

            search_params = {
              owner_klass_name: column.klass.name,
              association_name: column.method_name.to_s,
              enable_default_filters: enable_default_filters,
              remove_variables_from_default_filters: remove_variables_from_default_filters,
            }
            return Form::Element::Association::Base.add_params_to_url(url, search_params)
          end

          def selected_value
            value_ = value.is_a?(Array) ? value.first : value
            return unless value_.present?
            unless value_label_loaded?
              load_value_record
              return nil
            end
            {value: value_, label: value_label}
          end

          def selected_values
            s = selected_value
            [s] if s
          end

          def load_value_record
            value_ = value.is_a?(Array) ? value.first : value
            @record ||= target_klass&.find(value_) do
              mutate
            end
          end

          def value_label_loaded?
            @record&.loaded?
          end

          def value_label
            return unless @record&.loaded?
            return @record.try(@record.class.try(:name_attribute))
          end
        end

        class HasMany < Base; end
        class BelongsTo < Base; end
      end

      module Attachment
        class Base < ::Crm::Filters::Input::Base

          render do
          end

        end
      end
    end
  end
end
