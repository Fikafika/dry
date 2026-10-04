require 'components/form/element/layout/base'

class Form
  module Element
    module Layout
      class AdditionalFieldsContainer < ::Form::Element::Layout::Base

        render { content }

        def content
          DIV(ref: _ref, class: 'row') do
            if in_editor && children.length == 0
              DIV(class: 'form-editor-dropzone') do
              end
            end
            DIV(class: 'container-fluid') do
              children_render
              if show_dropdown?
                DIV(class: 'row') do
                  DIV(class: 'col text-right') do
                    DropDown(text: text, hidden_elements: hidden_elements).on(:select_element) do |element|
                      @hidden_elements = nil # clear cache
                      @selected = element.props[:id]
                      visible_elements[@selected] = true
                      mutate
                    end
                  end
                end
              end
            end
          end
        end

        private

        def children_render
          DIV(class: 'row') do
            children.each do |c|
              if in_editor
                child_layout do
                  c.render
                end
              else
                if self.form && visible_elements[c.props[:id]]
                  child_layout do
                    args = (@selected && c.props[:id] == @selected) ? {editing: true} : {}
                    self.form.render_child(c, prefix_path, record, conditions, in_hash, args)
                  end
                end
              end
            end
          end
        end

        def visible_elements
          return @visible_elements if @visible_elements
          @visible_elements ||= {}
          children.each do |c|
            if c.props[:requirement] == 'mandatory' || c.props[:requirement] == 'important' || child_has_value?(c)
              @visible_elements[c.props[:id]] = true
            end
          end
          @visible_elements
        end

        def show_dropdown?
          in_editor || hidden_elements&.any?
        end

        def child_has_value?(c)
          return false if in_editor || !self.form
          return false unless c.props[:record]
          if c.props[:record].class.reflect_on_attachment(c.props[:attribute_name])
            c.props[:record].send(c.props[:attribute_name])&.attached?
          else
            !c.props[:record].send(c.props[:attribute_name]).blank?
          end
        end

        def child_layout
          DIV(class: col_size) do
            yield
          end
        end

        def col_size
          other_params[:col_size] || 'col-6'
        end

        def hidden_elements
          @hidden_elements ||= children.select{|c| !visible_elements[c.props[:id]]}
        end

        class DropDown < HyperComponent
          param :text, default: nil
          param :hidden_elements, default: []

          fires :select_element

          render do
            A(href: "#add_data", class: "btn btn-transparent-yiq dropdown-toggle", "data-toggle": "dropdown") do
              text || I18n.t('form/element/layout/additional_fields_container/drop_down.label')
            end
            DIV(class: 'dropdown-menu') do
              hidden_elements.each do |element|
                A(href: '#', class: 'dropdown-item') do
                  displayed_label(element)
                end.on(:click) do |event|
                  event.prevent_default
                  select_element!(element)
                end
              end
            end
          end

          def displayed_label(element)
            # same as element/base#displayed_label
            element.props[:label] || element.props[:record]&.class&.human_attribute_name(element.props[:attribute_name])
          end
        end

      end
    end
  end
end
