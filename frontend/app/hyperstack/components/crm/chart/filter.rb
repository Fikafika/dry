class Crm
  module Chart
    module Filter

      def self.create_element(options = {})
        if options[:chart]&.type
          klass = "Crm::Chart::Filter::#{options[:chart]&.type}".safe_constantize
        end
        klass ||= Base
        return klass.create_element(options)
      end

      class Base < HyperComponent

        param :chart
        param :value
        param :klass

        fires :change

        render { content }

        def content
          return unless column
          if @list.blank? || @list != @old_value
            @list = Array(value) || []
          end

          DIV(class: "container") do
            list.each_with_index do |v, i|
              DIV(class: "row mb-2") do
                input_group(v, i)
              end
            end
            DIV(class: 'row mb-2') do
              add_button
            end
          end
        end

        def list
          @list
        end

        def input_group(value, i)
          DIV(class: 'd-flex align-items-stretch w-100 flex-nowrap') do
            DIV(class: 'input-group flex-nowrap') do
              value_input(value).on(:change) do |v|
                v = workaround_boolean_value(v) # convert from string because #change! convert false to nil
                list[i] = v
                @old_value = list
                mutate
                change!(list)
              end
            end
            remove_button(i)
          end
        end

        def value_input(value)
          ::Crm::Filters::Input.klass_from_type(value_input_type).create_element(value: value, column: column, auto_default_value: false).render
        end

        def operator
          if chart.type == 'Line'
            'equal'
          else
            nil
          end
        end

        def column
          return @column if @column
          return unless klass
          group = chart.groups.detect{|g| g.axis == 'x'}
          return unless group
          if group.source == 'attr'
            @column = klass.datatable_column_by_name[group.attr]
          else
            column_klass = Crm::Datatable::Column::Attribute::Base
            @column = column_klass.new(name: 'fake', css_class: '', root_klass: klass, klass: klass, method_name: 'fake', depth: 0) # how to do with data comuted in opensearch ?
          end
          return @column
        end

        def value_input_type
          @value_input_type ||= column.class.name.sub('Crm::Datatable::Column::', '')
        end

        def add_button
          A(href: '#add', class: "btn btn-sm btn-light") do
            SPAN(class: "fa fa-plus") {}
          end.on(:click) do |event|
            event.prevent_default
            list << '' # TODO
            @old_value = list
            mutate
          end
        end

        def remove_button(i)
          A(href: "#remove", class: "btn btn-sm btn-light d-flex align-items-center ml-2") do
            SPAN(class: "fa fa-trash") do
            end
          end.on(:click) do |event|
            event.prevent_default
            list&.delete_at(i)
            v = list
            v = nil if v.blank?
            change!(v)
            mutate
          end
        end

        def workaround_boolean_value(value)
          value = false if value == 'false'
          value = true if value == 'true'
          return value
        end

      end

      class Line < Base

        render { content }

        def content
          return unless column

          if @list.blank? || @list != @old_value
            @list = Array(value) || []
            @list = @list.first if @list.first.is_a?(::Array) # why chart date fitlers are buggy ?
            @list[0] ||= nil
            @list[1] ||= nil
          end

          DIV(class: "container") do
            list.each_with_index do |v, i|
              DIV(class: "row mb-2") do
                value_input(value).on(:change) do |v|
                  list[i] = v
                  @old_value = list
                  mutate
                  change!(list)
                end
              end
            end
          end
        end

      end
    end
  end
end
