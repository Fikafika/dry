# TODO push submission data and ask for a document generator service

class Form
  module Element
    module Control
      class Print < Base
        render { content }

        def render_input
          stub # TODO
        end

        def render_readonly
          DIV(ref: _ref, class: 'form-group row') do
            DIV(class: "col") do
              SPAN do
                A(href: 'print') do
                  text
                end # TODO on click
              end
            end
          end
        end

        def render_edit_in_place
          stub # don't render ?
        end

      end
    end
  end
end
