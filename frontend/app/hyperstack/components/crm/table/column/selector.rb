class Crm
  class Table
    module Column
      class Selector < ::HyperComponent

        param :klass
        param :selected_columns, default: nil
        param :prefix, default: nil

        track_changes :klass, :selected_columns

        fires :change

        render { content }

        def content
          init
          DIV(class: '') do
            DIV(class: 'd-flex flex-column align-items-end pr-2') do
              select_all_button_for_association
            end
            tree_items.each_with_index do |c, i|
              next if c[:parent_path].present? && !@collapsable_show[c[:parent_path]]

              DIV(class: "p-2 #{'border-top' if i > 0}", style: {marginLeft: "#{1.6 * c[:depth]}em"}) do
                if c[:items]&.any?
                  DIV(class: 'd-flex flex-nowrap') do
                    DIV(class: 'd-flex align-items-center flex-grow-1') do
                      if i > 0
                        I(class: "mr-2 fa-fw fas fa-#{@collapsable_show[c[:path]] ? 'minus' : 'plus'}") do
                        end.on(:click) do |event|
                          @collapsable_show[c[:path]] = !@collapsable_show[c[:path]]
                          mutate
                        end
                        checkbox(c[:klass], c[:method_name], c[:path])
                      end
                    end
                    DIV(class: '') do
                      select_all_button_for_association
                    end
                  end

                  if i == 0 || @collapsable_show[c[:path]]
                    DIV(style: {marginLeft: "#{1.6 * (c[:depth] + 1)}em"}) do
                      checkboxes(c[:items])
                    end
                  end
                else
                  checkboxes([c])
                end
              end
            end
          end
        end

        def init
          if klass_changed?
            @collapsable_show = {}
            @tree_items = nil
          end
          if klass
            observe klass.options_for_indexed_json
          end
        end

        def checkboxes(columns)
          column_grid(columns, 4, 'd-none d-xl-flex')           # xl
          column_grid(columns, 3, 'd-none d-lg-flex d-xl-none') # lg
          column_grid(columns, 2, 'd-none d-md-flex d-lg-none') # md
          column_grid(columns, 1, 'd-sm-flex d-md-none')        # sm
        end

        def column_grid(columns, count, visibility_class)
          col_class = "col-#{12 / count}"
          DIV(class: "#{visibility_class} row pt-2") do
            columns.in_groups(count, false).each do |subgroup|
              DIV(class: col_class) do
                subgroup.each do |column|
                  checkbox(column[:klass], column[:method_name], column[:path])
                end
              end
            end
          end
        end

        def checkbox(klass, method_name, path)
          input_id = "check-#{prefix}-#{path.gsub(/\./, '--')}"
          DIV(class: "input-group") do
            DIV(class: "form-check") do
              INPUT(class: "form-check-input", type: "checkbox", name: "column", value: path, id: input_id, checked: selected_columns&.include?(path) ) do
              end.on(:change) do |event|
                if event.target.checked
                  selected_columns.push(path)
                else
                  selected_columns.delete(path)
                end
                change!(selected_columns)
                mutate
              end
              LABEL(class: "form-check-label", htmlFor: input_id) do
                klass.human_attribute_name(method_name)
              end
            end
          end
        end

        def self.all_paths_for(klass)
          calculate_tree(klass).flat_map do |node|
            current_paths = []
            current_paths << node[:path] if node[:path].present?
            children_paths = (node[:items] || []).map { |item| item[:path] }
            current_paths + children_paths
          end.compact.uniq
        end

        def self.calculate_tree(klass)
          return [] unless klass&.options_for_indexed_json&.any?
          tree = []
          if klass.options_for_indexed_json['only']&.any?
            tree << {
              depth: 0,
              items: klass.attribute_and_attachment_names_from_options_for_indexed_json.map do |attr|
                {klass: klass, method_name: attr, path: attr, depth: 0}
              end
            }
          end
          tree.concat(klass.travel_through_options_for_indexed_json do |k, attr, assoc, attachment, path, options_for_indexed_json_|
            next [] unless assoc
            [{
              path: path.join('.'),
              klass: k,
              method_name: assoc.name,
              parent_path: path[0..-2].join('.'),
              depth: path.length,
              items: assoc.klass&.attribute_and_attachment_names_from_options_for_indexed_json(options_for_indexed_json_)&.map do |a|
                { path: (path + [a]).join('.'), klass: assoc.klass, method_name: a, depth: path.length + 1 }
              end || []
            }]
          end)
          tree
        end

        def tree_items
          @tree_items ||= self.class.calculate_tree(klass)
        end

        def select_all_button_for_association
          # TODO
        end

      end
    end
  end
end
