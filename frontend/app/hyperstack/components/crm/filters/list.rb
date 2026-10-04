require 'components/crm/filters/normalization'
require 'components/crm/filters/variable_input'

class Crm
  module Filters
    class List < HyperComponent
      extend ::Crm::Filters::Normalization

      param :list
      param :column
      param :root_klass
      param :get_variable, default: nil
      param :variable_possible_values, default: nil
      param :default_menu, default: nil
      param :enable_default_filters, default: true
      param :remove_variables_from_default_filters, default: true

      collect_other_params_as :other_params

      fires :change

      render do
        DIV(class: "container") do
          list.each_with_index do |filter_el, i|
            DIV(class: "row mb-2") do
              input_group(filter_el, i)
            end
          end
          DIV(class: 'row mb-2') do
            A(href: "#add", class: "btn btn-sm btn-light") do
              SPAN(class: "fa fa-plus") do
              end
            end.on(:click) do |event|
              event.prevent_default
              list.push(["and", default_operator, ""])
              change!(list)
              mutate
            end
          end
        end
      end

      def default_operator
        if default_menu
          default_menu[0]
        else
          column&.default_operator || 'contains'
        end
      end

      def menu
        if default_menu
          default_menu
        else
          column&.filters_menu || []
        end
      end

      def input_group(filter_el, i)
        DIV(class: 'd-flex align-items-stretch w-100 flex-nowrap') do
          and_or_menu(filter_el, i)

          DIV(class: 'input-group flex-nowrap') do
            operator_menu(filter_el)

            value_input(filter_el[1], filter_el[2]).on(:change) do |value|
              value = workaround_boolean_value(value) # convert from string because #change! convert false to nil
              list[i] = filter_el
              mutate filter_el[2] = value
              change!(list)
            end

            if get_variable || variable_possible_values
              type_menu(filter_el, i)
            end
          end

          remove_button(i)
        end
      end

      def workaround_boolean_value(value)
        value = false if value == 'false'
        value = true if value == 'true'
        return value
      end

      def and_or_menu(filter_el, i)
        DIV(class:"dropdown mr-2") do
          if i == 0
            if other_params[:show_empty_and_or]
              empty_and_or
            else
              BUTTON(class: "btn", style: {"minWidth": button_width, cursor: 'default', color: '#00000000'}){}
            end
          else
            BUTTON(class: "btn input-group-text dropdown-toggle", type: "button", "data-toggle": "dropdown", style: {"minWidth": button_width}) do
              filter_el[0] ||= "and"
              I18n.t("shared.#{filter_el[0]}")
            end
          end
          DIV(class: "dropdown-menu mb-2") do
            ["and", "or"].each do |op|
              A(class:"dropdown-item", href: '#') do
                I18n.t("shared.#{op}")
              end.on(:click) do |evt|
                evt.prevent_default
                filter_el[0] = op
                change!(list)
                mutate
              end
            end
          end
        end
      end

      def empty_and_or
        BUTTON(class: "btn input-group-text bg-transparent", style: {"minWidth": button_width, cursor: 'default', color: '#00000000'}) do
          I18n.t("shared.and")
        end.on(:focus) do |event|
          event.target.blur
        end
      end

      def button_width
        other_params[:button_width] || "60px"
      end

      def operator_menu(filter_el)
        DIV(class:"dropdown input-group-prepend") do
          BUTTON(class: "btn input-group-text dropdown-toggle", type: "button", "data-toggle": "dropdown", style: {"minWidth": menu_width}) do
            filter_el[1] ||= default_operator
            I18n.t("crm.filters_op.#{filter_el[1]}")
          end
          DIV(class: "dropdown-menu") do
            menu.each do |filter|
              A(class: "dropdown-item #{'active' if filter == filter_el[1]}", href: '#add_filter') do
                I18n.t("crm.filters_op.#{filter}")
              end.on(:click) do |evt|
                evt.prevent_default
                filter_el[2] = nil unless compatible_filters?(filter_el[1], filter)
                filter_el[1] = filter
                change!(list)
                mutate
              end
            end
          end
        end
      end

      def menu_width
        other_params[:menu_width] || "auto"
      end

      def value_input(operator, value)
        if value.try(:has_key?, :variable)
          if variable_possible_values
            VariableInput(value: value[:variable], possible_values: matching_variable_possible_values)
          else
            DIV(class: 'input-group-prepend form-control flex-grow-1') do
              variable = value[:variable]
              DIV(class: 'overflow-hidden cursor-default', title: variable_title(variable)) do
                variable_path(variable)
              end
            end
          end
        else
          if operator_arity(operator) > 1
            type = column.class.name.sub('Crm::Datatable::Column::', '')
            Input.klass_from_type(type).create_element(
              key: column.name,
              value: value,
              column: column,
              operator: operator,
              enable_default_filters: enable_default_filters,
              remove_variables_from_default_filters: remove_variables_from_default_filters,
            ).render
          else
            DIV(class: 'flex-grow-1') do
            end
          end
        end
      end

      def matching_variable_possible_values
        return variable_possible_values unless variable_possible_values && column
        col_type = field_match_type(column.klass, column.method_name)
        return variable_possible_values unless col_type
        variable_possible_values.select do |o|
          field_match_type(root_klass, o[:value]) == col_type
        end
      end

      def field_match_type(klass, method_name)
        if klass.attributes[method_name]
          [:attribute, klass.attributes[method_name]['type']]
        elsif (assoc = klass.reflect_on_association(method_name))
          [:association, assoc.klass&.name]
        elsif klass.indexable_virtual_attributes[method_name]
          [:attribute, klass.indexable_virtual_attributes.dig(method_name, 'type')]
        end
      end

      def operator_arity(op)
        [
          'empty',
          'not_empty',
          'today',
          'this_month',
          'this_week',
          'this_year',
          'past',
          'future',
          'previous_days',
          'following_days',
        ].include?(op) ? 1 : 2
      end

      def type_menu(filter_el, i)
        value_type = (filter_el[2].try(:has_key?, :variable) ? 'variable' : 'value')
        DIV(class: "dropdown input-group-append") do
          A(href: '#', class: "btn input-group-text dropdown-toggle w-100", type: "button", "data-toggle": "dropdown", title: I18n.t("crm.filters_type.#{value_type}")) do
            I(class: "fa fa-#{value_type == 'variable' ? 'crosshairs' : 'pen-to-square'}")
          end
          DIV(class: "dropdown-menu") do
            ['value', 'variable'].each do |type|
              A(class: "dropdown-item", href: "#") do
                I18n.t("crm.filters_type.#{type}")
              end.on(:click) do |event|
                event.prevent_default
                if type == 'variable'
                  filter_el[2] = {variable: nil} unless filter_el[2].try(:[], :variable)
                  get_variable&.call(
                    Proc.new do |v|
                      list[i][2] = {variable: v} # use i because mutate change filter_el
                      change!(list)
                      mutate
                    end
                  )
                else
                  filter_el[2] = nil
                end
                mutate
              end
            end
          end
        end
      end

      def remove_button(i)
        A(href: "#remove", class: "btn btn-sm btn-light d-flex align-items-center ml-2") do
          SPAN(class: "fa fa-trash") do
          end
        end.on(:click) do |event|
          event.prevent_default
          list&.delete_at(i)
          change!(list)
          mutate
        end
      end

      def variable_title(variable)
        return unless variable
        human_path(root_klass, variable.split('.')).join(' > ')
      end

      def variable_path(variable)
        return unless variable
        path = human_path(root_klass, variable.split('.'))
        path.each_with_index do |p, i|
          SPAN{ p }
          SPAN(class: 'fa fa-fw fa-chevron-right p-1') {} unless i == path.length - 1
        end
      end

      def human_path(klass, path)
        return [] unless klass && path&.any?
        result = []
        begin
          result << klass.model_name.human
          path.each do |m|
            result << klass.human_attribute_name(m)
            reflection = klass.reflect_on_association(m)
            klass = reflection&.klass if reflection
          end
        rescue
        end
        return result
      end

      def self.convert_to_hash(list, column, simplify: true, include_name: false, name_without_brackets: false)
        list_ = list.select{|f| f != ['and', column.default_operator, '']}
        return unless list_

        if include_name
          name = column.name
          if name_without_brackets
            name = name.gsub('[].', '.')
          end
          return nested_array_to_hash(list_, name)
        else
          return nested_array_to_hash(list_)
        end
      end

      def self.convert_from_hash(hash, normalize: true, include_name: false, name_without_brackets: false)
        hash = {'a' => hash}
        result = hash_to_array(hash, normalize: normalize)
        return result.first.try(:[], 2) || []
        return result
      end

      def self.clean(filter_list, column)
        filter_list.select{|f| f != ['and', column.default_operator, '']}
      end

      def compatible_filters?(f1, f2)
        return false if f1.to_s =~ /contains_id/ && f2.to_s =~ /contains_name/
        return false if f1.to_s =~ /contains_name/ && f2.to_s =~ /contains_id/
        return true
      end

    end
  end
end
