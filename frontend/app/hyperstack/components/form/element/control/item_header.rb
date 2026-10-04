class Form
  module Element
    module Control
      class ItemHeader < Base

        render { content }

        def render_input
          layout_for_nested_item do
            if orderable?
              down_btn
              up_btn
            end
            DIV(class: 'flex-grow-1'){}  # spacer
            delete_btn
          end
        end

        def render_readonly
        end

        def render_edit_in_place
        end

        private

        def layout_for_nested_item
          if other_params[:embeded]
            DIV(ref: _ref, class: 'row') do
              DIV(class: 'col') do
                DIV(class: "d-flex mb-2 #{'border-top' if index != 0}") do
                  yield
                end
              end
            end
          else
            DIV(ref: _ref, class: 'd-flex mb-2') do
              yield
            end
          end
        end

        def orderable?
          values && values.length > 1 && record&.class&.attributes&.dig('position')
        end

        def can_delete?
          min.nil? || values.nil? || values.length > min
        end

        def min
          other_params[:min]
        end

        def delete_btn
          return unless can_delete?
          A(href: '#delete', class: 'btn btn-transparent-light') do
            if text
              text
            else
              I(class: 'fa fa-trash'){}
            end
          end.on(:click) do |event|
            event.prevent_default
            Modal.confirm(title: I18n.t('shared.delete')) do
              form.submission.destroy(prefix_path)
              form_change
            end
          end
        end

        def up_btn
          A(href: '#up', class: "btn btn-transparent-light #{'disabled' if index == 0}") do
            I(class: 'fa fa-chevron-right fa-rotate-270'){}
          end.on(:click) do |event|
            event.prevent_default
            swap(values[index], next_value(-1))
            form_change
          end
        end

        def down_btn
          A(href: '#down', class: "btn btn-transparent-light #{'disabled' if index == values.length - 1}") do
            I(class: 'fa fa-chevron-right fa-rotate-90'){}
          end.on(:click) do |event|
            event.prevent_default
            swap(values[index], next_value)
            form_change
          end
        end

        def form_change
          form.enable
          form.mutate
          form.change
        end

        def index
          other_params[:index]
        end

        def values
          return form.submission.read_association(prefix_path[0..-2])
        end

        def next_value(inc = 1)
          values = self.values

          i = index + inc
          while i > 0 && values[i]['_destroy']
            i += inc
          end
          return if i < 0 || i >= values.length

          return values[i]
        end

        def swap(v1, v2)
          return unless v1 && v2 && v1 != v2

          values = self.values

          v1[:position] ||= 0
          v2[:position] ||= 0

          if v1[:position] == v2[:position]
            form.submission.write_from_user(prefix_path + [:position], v1[:position] + 1)
          else
            i1 = values.index(v1)
            i2 = values.index(v2)

            # swap position
            p1 = v1[:position]
            p2 = v2[:position]

            form.submission.write_from_user(prefix_path[0..-2] + [i1, :position], p2)
            form.submission.write_from_user(prefix_path[0..-2] + [i2, :position], p1)
          end
        end

      end
    end
  end
end
