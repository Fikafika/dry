require 'components/form/element/base'

class Form
  module Element
    module Basic
      class Base < ::Form::Element::Base
        render { content }

        def render_readonly
        end

        def render_input
          render_readonly
        end

        def render_diff
          render_readonly
        end

        def render_edit_in_place
          render_readonly
        end

        def render_read_only
          render_readonly
        end

        def layout_readonly
          if in_editor
            DIV(ref: _ref, class: 'row') do
              DIV(
                class: 'col',
                style: { minHeight: '20px', display: 'block' },
              ) do
                yield if block_given?
              end
            end
          else
            yield if block_given?
          end
        end

      end
    end
  end
end
