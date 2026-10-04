require 'components/crm/filters/normalization'
require 'components/crm/filters/merge'

class Crm
  module Filters
    class AdvancedList < HyperComponent
      extend ::Crm::Filters::Normalization
      extend ::Crm::Filters::Merge

      param :klass
      param :root_klass
      param :list
      param :get_variable, default: nil
      param :variable_possible_values, default: nil
      param :depth, default: nil
      param :default_menu, default: nil
      param :enable_default_filters, default: true
      param :remove_variables_from_default_filters, default: true

      collect_other_params_as :other_params

      fires :change

      render { content }

      def content
        DIV(class: "container") do
          if can_render_list?
            each_row_with_key do |column_filters, i, key|
              if column_filters[0] == 'separator'
                DIV(class: 'row mb-2', key: key) do
                  DIV(class: 'flex-grow-1') do
                    DIV(class: 'border-bottom my-3') do
                    end
                  end
                  remove_column(i)
                end
              else
                DIV(class: 'row mb-2', key: key) do
                  and_or_menu(column_filters, i)
                  choose_column(column_filters, i)
                  remove_column(i)
                end
                if column_filters[1]
                  DIV(class: 'row pl-4', key: "#{key}v") do
                    List(
                      list: column_filters[2],
                      root_klass: root_klass,
                      column: column_filters[1],
                      show_empty_and_or: true,
                      get_variable: get_variable,
                      variable_possible_values: variable_possible_values,
                      default_menu: default_menu,
                      enable_default_filters: enable_default_filters,
                      remove_variables_from_default_filters: remove_variables_from_default_filters,
                    ).on(:change) do |l|
                      list[i][2] = l
                      change!(list)
                    end
                  end
                end
              end
            end
          end
          DIV(class: 'row') do
            A(href: '#add', class: "btn btn-sm btn-light #{'disabled' if add_btn_disabled?}") do
              SPAN(class: "fa fa-plus") {}
            end.on(:click) do |event|
              event.prevent_default
              add_btn_click(event)
            end

            DIV(class: 'flex-grow-1') {}

            add_separator unless list.last.try(:[], 0) == 'separator'
          end
        end
      end

      def each_row_with_key
        counts = Hash.new(0)
        list.each_with_index do |column_filters, i|
          yield column_filters, i, row_key(counts, column_filters)
        end
      end

      def row_key(counts, column_filters)
        name = column_filters[0] == 'separator' ? 'separator' : column_filters[1]&.name.to_s
        counts[name] += 1
        "#{name}-#{counts[name]}"
      end

      def can_render_list? # can be redefined
        unless klass&.options_for_indexed_json&.loaded?
          observe klass.options_for_indexed_json
          return false
        end
        return true
      end

      def and_or_menu(column_filters, i)
        DIV(class:"dropdown mr-2") do
          if i == 0
            empty_and_or
          else
            BUTTON(class: "btn input-group-text dropdown-toggle", type: "button", "data-toggle": "dropdown", style: {"minWidth": button_width}) do
              column_filters[0] ||= "and"
              I18n.t("shared.#{column_filters[0]}")
            end
          end
          DIV(class: "dropdown-menu") do
            ["and", "or"].each do |op|
              A(class:"dropdown-item", href: '#add_column') do
                I18n.t("shared.#{op}")
              end.on(:click) do |evt|
                evt.prevent_default
                column_filters[0] = op
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

      def choose_column(column_filters, i)
        Form(record: HyperResource::Base.new(column: column_filters[1]), class: 'flex-grow-1', nested: true) do
          Form::Element::Attribute::SerializedArray(attribute_name: 'column', possible_values: column_possible_values, accept_empty_value: true, editor: 'tree_select', show_label: false, class: 'mb-0').on(:change) do |attr, form|
            column = form.submission.params.dig('hyper_resource', 'column')
            list[i][1] = column
            if default_menu
              list[i][2] = [["and", default_menu[0], ""]]
            else
              list[i][2] = [["and", column.default_operator, ""]]
            end
            change!(list)
            mutate
          end
        end
      end

      def column_possible_values
        return unless klass.options_for_indexed_json.loaded?
        @column_possible_values ||= build_column_possible_values(klass, klass.options_for_indexed_json, 0)
      end

      def build_column_possible_values(klass, options_for_indexed_json, current_depth, prefix = '')
        result = []
        options_for_indexed_json[:only]&.each do |a|
          column = self.klass.datatable_column_by_name[prefix + a]
          next unless column
          result << {label: klass.human_attribute_name(a), value: column}
        end
        if depth && current_depth > depth
          return result
        end
        options_for_indexed_json[:include]&.each do |a, v|
          assoc = klass.reflect_on_association(a)
          next unless assoc
          name = "#{prefix}#{a}"
          name = "#{name}[]" if assoc.collection?
          column = self.klass.datatable_column_by_name[name]
          o = {label: klass.human_attribute_name(a), value: column}
          children = build_column_possible_values(assoc.klass, v, current_depth+1, "#{name}.") if assoc.klass
          o[:options] = children if children&.any?
          next unless column || children&.any?
          result << o
        end
        result = result.sort_by{|o| o[:label].to_s }
        return result
      end

      def menu_width
        other_params[:menu_width] || "auto"
      end

      def remove_column(i)
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

      def add_btn_disabled? # can be redefined
        false
      end

      def add_btn_click(event) # can be redefined
        return unless column_possible_values&.any?
        add_column(column_possible_values.first[:value])
        mutate
      end

      def add_column(column)
        return unless column
        if default_menu
          list.push(["and", column, [["and", default_menu[0], '']]])
        else
          list.push(["and", column, [["and", column.default_operator, '']]])
        end
        change!(list)
      end

      def add_separator
        A(href: '#add_separator', class: "btn btn-sm btn-light #{'disabled' if add_btn_disabled?}") do
          ')'
        end.on(:click) do |event|
          event.prevent_default
          list&.push(['separator'])
          change!(list)
          mutate
        end

        # hidden and have same size as remove_column
        DIV(class: "btn btn-sm btn-light d-flex align-items-center ml-2", style: {opacity: 0}) do
          SPAN(class: "fa fa-trash"){}
        end
      end

      def self.convert_to_hash(list, name_without_brackets: false, normalize: false)
        hash = array_to_hash(
          list,
          convert_attr: ->(column) { to_column_name(column.name, name_without_brackets: name_without_brackets) }
        )
        if normalize
          hash = normalize(hash)
        end
        return hash
      end

      def self.convert_from_hash(hash, klass, normalize: true, name_without_brackets: false)
        return hash_to_array(
          hash,
          normalize: normalize,
          convert_attr: ->(column_name) { find_column(klass, from_column_name(column_name, name_without_brackets: name_without_brackets)) }
        )
      end

      def self.to_column_name(name, options = {})
        result = name
        if options[:name_without_brackets]
          result = result.split('.').join('[].')
        end
        return result
      end

      def self.from_column_name(name, options = {})
        result = name
        if options[:name_without_brackets]
          result = result.gsub('[].', '.')
        end
        return result
      end

      def self.find_column(klass, name)
        klass.datatable_column_by_name[name]
      end

      def self.clean(filter_list, column)
        # TODO
      end

    end
  end
end
