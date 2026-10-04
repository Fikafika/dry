require 'components/form/element/layout/container'

class Form
  module Element
    module Layout
      class Page < ::Form::Element::Layout::Container

        param :icon, default: nil
        param :initialize_hidden_element, default: false

        render { content }

        def content
          if in_editor
            content_in_editor
          else
            container do
              children_render
            end
          end
        end

        def content_in_editor
          @number = nil
          DIV(ref: _ref, class: 'row form-editor-page') do
            DIV(class: 'container-fluid') do
              DIV(class: 'row form-editor-page-header') do
                DIV(class: 'col text-center') do
                  label.present? ?  label : "Page #{number}"
                end
              end
              children_render
            end
          end
        end

        def number
          return @number if @number

          if in_editor
            form.page_of(other_params[:id])
          else
            @number = form.page_counter
            form.page_counter += 1
            form.pages[@number] = {
              label: self.label,
              icon: self.icon
            }
            return @number
          end
        end

        def container
          if initialize_hidden_element
            DIV(ref: _ref, class: 'row', style: {display: form.submission.page == number ? "block" : "none"}) do
              DIV(class: 'container-fluid') do
                yield
              end
            end
          else
            if form.submission.page == number
              DIV(ref: _ref, class: 'row') do
                DIV(class: 'container-fluid') do
                  yield
                end
              end
            else
              stub
            end
          end
        end
      end
    end
  end
end
