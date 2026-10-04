require 'components/form/element/base'
class Form
  class Editor
    module Panel
      module Layout
        class ConditionFormula < ::Form::Editor::Panel::ConditionFormula

          class AdvancedList < ::Form::Editor::Panel::ConditionFormula::AdvancedList
            param :get_elements_path

            def can_render_list? # redefined
              true
            end

            def add_btn_disabled? # redefined
              @add_btn_clicked
            end

            def add_btn_click(event) # redefined
              mutate @add_btn_clicked = true

              get_elements_path.call( # TODO can be simplified ?
                Proc.new do |v|
                  @add_btn_clicked = false
                  add_column(self.class.find_column(v[:root_klass], v[:path_name]))
                  mutate
                end
              )
            end

            def column_possible_values # TODO retrieve all element paths from form editor
              return [] unless list&.any?
              list.map do |e|
                column = e[1]
                {label: column.human_path.join(' > '), value: column}
              end
            end

            class List < ::Form::Editor::Panel::ConditionFormula::AdvancedList::List
            end
          end

        end
      end
    end
  end
end
