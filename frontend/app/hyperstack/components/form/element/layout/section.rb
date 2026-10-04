# backtick_javascript: true
require 'components/form/element/layout/base'

class Form
  module Element
    module Layout
      class Section < ::Form::Element::Layout::Base

        render { content }

        before_mount do
          load_collapsed_state
        end

        def content
          card_classes = [
            'card',
            section_classes,
            css_classes&.dig(:collapsed),
            css_classes&.dig(:show_border),
            css_classes&.dig(:border_color)
          ].join(' ')
          DIV(ref: _ref, class: card_classes) do
            section_header
            section_body
          end
        end

        def toggle_icon_class
          if @is_collapsed
            'fas fa-chevron-down ml-2'
          else
            'fas fa-chevron-up ml-2'
          end
        end

        def section_header
          DIV(class: header_classes) do
            if has_collapsible_class?
              A(
                href: '#',
                class: "section-toggle d-flex align-items-center text-decoration-none w-100 #{css_classes&.dig(:collapsible)}",
                style: { cursor: 'pointer', userSelect: 'none', color: 'inherit' }
              ) do
                render_title_element("mb-0 flex-grow-1 #{css_classes&.dig(:font_size)}")
                I(class: toggle_icon_class)
              end.on(:click) do |e|
                e.prevent_default
                toggle
              end
            elsif label
              render_title_element("mb-0 #{css_classes&.dig(:font_size)}")
            end
          end
        end

        def render_title_element(css_class)
          title_classes = [css_class]
          DIV(class: title_classes.join(' ')) { label }
        end

        def section_body
          body_classes = ['card-body', css_classes&.dig(:body)]
          DIV(
            class: body_classes.join(' '),
            style: @is_collapsed ? { display: 'none' } : { display: 'block' }
          ) do
            children_render unless @is_collapsed
          end
        end

        def section_classes
          [
            'form-section',
            margin_classes,
            css_classes&.dig(:full_width),
            css_classes&.dig(:section),
          ].join(' ')
        end

        def header_classes
          [
            'card-header',
            css_classes&.dig(:color),
            css_classes&.dig(:show_header),
            css_classes&.dig(:header)
          ].join(' ')
        end

        def toggle
          @is_collapsed = !@is_collapsed
          save_collapsed_state
          mutate
        end

        def storage_key
          "section_#{storage_key_parts.join('_')}"
        end

        def margin_classes
          [
            css_classes&.dig(:margin_top).presence,
            css_classes&.dig(:margin_bottom).presence || 'mb-3'
          ].compact.join(' ')
        end


        private


        def has_collapsible_class?
          collapsible_value = css_classes&.dig(:collapsible)
          collapsible_value.present? && collapsible_value != 'not-collapsible'
        end

        def storage_key_parts
          [
            form&.dynamic_form&.id || 'form',
            other_params[:id],
            label&.parameterize
          ].reject(&:blank?)
        end

        def default_state
          false
        end

        def load_collapsed_state
          if in_editor
            @is_collapsed = false
            return
          end
          return unless has_collapsible_class?
          @is_collapsed = default_state
          saved = `localStorage.getItem(#{storage_key})`
          @is_collapsed = (saved == 'true') if saved
        end

        def save_collapsed_state
          `localStorage.setItem(#{storage_key}, #{@is_collapsed.to_s})`
        end
      end
    end
  end
end