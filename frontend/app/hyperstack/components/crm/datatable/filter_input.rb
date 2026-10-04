require 'components/crm/filters/find_and_update'


class Crm::Datatable

  def FilterInput(args)
    column = args[:column]
    filter_input_class = "Crm::Datatable::FilterInput::#{column.class.name.sub('Crm::Datatable::Column::', '')}".safe_constantize || Crm::Datatable::FilterInput::Base
    filter_input_class.create_element(args).render
  end

  module FilterInput

    class Base < HyperComponent
      include ::Crm::Filters::FindAndUpdate

      param :name
      param :search_query
      param :reload
      param :column

      fires :launch_search
      fires :click_icon_filter

      after_mount do
        fix_datatable_column_mousedown
      end

      def search_query_value
        search_query_filter[column.default_operator] rescue nil
      end

      track_changes :search_query_value

      def search_query_filter
        return extract_filter_from_search_query(search_query, name)
      end

      after_new_params do
        if search_query_value_changed?
          @original_input_value = @input_value = search_query_value
        end
      end

      render do
        DIV(class: 'w-100 pl-1 pr-1 pb-1 d-flex flex-row') do
          render_input
          DIV(class: "flex-shrink-1") do
            if input_changed?
              render_apply_input_button
            else
              render_open_filter_modal_button
            end
          end
        end
      end

      def render_input
        INPUT(
          type: input_type,
          name: input_name,
          value: @input_value,
          placeholder: "",
          class: "form-control form-control-sm",
        ) do
        end.on(:change) do |evt|
          @input_value = evt.target.value
          mutate
        end.on(:key_press) do |event|
          key = event.which
          if key == 13 # ENTER
            event.stop_propagation
            event.prevent_default
            launch_query
          end
        end.on(:click) do |event|
          event.current_target.select
        end
      end

      def input_changed?
        @input_value != @original_input_value
      end

      def render_apply_input_button
        DIV(class: "btn btn-sm btn-primary pl-1 pr-1 shadow-none") do
          SPAN(class: "fa fa-check fa-fw") do
          end
        end.on(:click) do |event|
          event.stop_propagation
          event.prevent_default
          launch_query
          mutate
        end
      end

      def render_open_filter_modal_button
        DIV(class: "btn btn-sm btn-transparent-light-yiq pl-1 pr-1 #{filtered? ? 'active' : ''} shadow-none") do # if true, it's a multifiltered input (see before_mount)
          SPAN(class: "fa fa-filter fa-fw") do
          end
        end.on(:click) do |event|
          event.stop_propagation
          event.prevent_default
          click_icon_filter!
        end
      end

      def filtered?
        search_query_filter.present?
      end

      def input_name
        "Filters[#{name}]"
      end

      def input_type
        'text'
      end

      def launch_query
        @original_input_value = @input_value
        update_filter_in_search_query(search_query, name, @input_value.present? ? filter_value : nil)
        launch_search!
      end

      def filter_value
        {column.default_operator => @input_value}
      end

    private

      def fix_datatable_column_mousedown
        # to prevent datatable columns from being moved when selecting text in filter input
        input = self.jq_node.find("[name=\"#{input_name}\"]")
        return unless input.length > 0
        input.on('mousedown') do |evt|
          evt.stop_propagation
        end
      end

    end

    module Attribute

      class Number < Base

        def input_type
          'number'
        end

        def filter_value
          {column.default_operator => column.convert_value_from_filter_input_value(@input_value)}
        end

      end

      class Integer < Number; end

      class Float < Number; end

      class Enum < Base

        def search_query_value
          column.convert_value_to_filter_input_value(super) rescue ''
        end


        def filter_value
          {column.default_operator => column.convert_value_from_filter_input_value(@input_value)}
        end

      end

      class Boolean < Enum; end

      class Date < Base

        def render_input
          INPUT(
            type: input_type,
            name: input_name,
            value: @input_value,
            step: 1,
            class: "form-control form-control-sm",
            style: {minWidth: 0}
          ) do
          end.on(:change) do |evt|
            @input_value = evt.target.value
            mutate
          end.on(:key_press) do |event|
            key = event.which
            if key == 13
              event.stop_propagation
              event.prevent_default
              launch_query
            end
          end.on(:click) do |event|
            event.current_target.select
          end
        end

        def input_type
          'date'
        end

        def search_query_value
          column.convert_value_to_filter_input_value(super) rescue ''
        end

        def filter_value
          {column.default_operator => column.convert_value_from_filter_input_value(@input_value)}
        end
      end

      class DateTime < Date
      end

      class TimeOfDay < Base

        def render_input
          INPUT(
            type: input_type,
            name: input_name,
            value: @input_value,
            step: 1,
            class: "form-control form-control-sm",
            style: {minWidth: 0}
          ) do
          end.on(:change) do |evt|
            @input_value = evt.target.value
            mutate
          end.on(:key_press) do |event|
            key = event.which
            if key == 13
              event.stop_propagation
              event.prevent_default
              launch_query
            end
          end.on(:click) do |event|
            event.current_target.select
          end
        end

        def input_type
          'time'
        end

        def search_query_value
          column.convert_value_to_filter_input_value(super) rescue ''
        end

      end

      class Type < Enum
      end

    end

    module Association

      class Base < Crm::Datatable::FilterInput::Base

        def render_input
          InputWithAutocomplete({
            input_args: input_args,
            search_url: search_url,
            return_string: true,
            template_result: Form::Element::Association::Base.template_result_ruby(target_klass),
            class: 'w-100',
          }).on(:key_enter) do |event, value|
            change_value(value)
          end.on(:select) do |event, value|
            change_value(value)
          end
        end

        def input_args
          contains_name_value = search_query.dig(:filters, name, 'contains_name') rescue nil
          result = {
            class: 'form-control form-control-sm',
            name: input_name,
          }
          result[:value] = contains_name_value[1] if contains_name_value && !@input_value
          result
        end

        def target_klass
          column.target_klass
        end

        def search_url
          target_klass_search_url || polymorphic_search_url
        end

        def target_klass_url
          target_klass&.collection_path
        end

        def target_klass_search_url
          url = target_klass_url
          return url unless url
          Form::Element::Association::Base.add_params_to_url(url,
            owner_klass_name: column.klass.name,
            association_name: column.method_name.to_s,
            remove_variables_from_default_filters: true,
          )
        end

        def polymorphic_search_url
          column.klass.parent.try(:search_path)
        end

        def change_value(value)
          if value
            if value.is_a? String
              return unless target_klass.name_attribute
              @input_value = value
              @input_type = :name
            else
              @selected_record = value[:record]
              @input_value = @selected_record[:id]
              @input_type = :id
            end
          end
          launch_query
        end

        def filter_value
          return {column.default_operator => @input_value} unless @input_type == :name
          {contains_name: [target_klass.name_attribute, @input_value]}
        end
      end

      class HasMany < Base
      end

      class BelongsTo < Base
      end
    end

  end

end

