# backtick_javascript: true
class Form
  class Integrator
    module Panel
      class IframeSection < HyperComponent
        param :iframe_code, default: ""
        param :preview_url, default: ""
        param :iframe_height, default: 600
        param :modal_params, default: nil
        param :accordion_style

        fires :preview_requested
        fires :copy_link_requested
        fires :copy_code_requested
        fires :height_changed
        fires :show_modal_requested
        fires :close_modal_requested

        before_mount do
          @show_color_picker = false
        end

        render do
          render_code_section
          ::Form::Element::Layout::Accordion(
            title: I18n.t("crm.form_integrator.heading_message_control"),
            style: accordion_style,
          ) do
            render_style_controls
          end
          render_action_buttons
          render_modal if modal_params
        end

        private

        def iframe_size_mappings
          @iframe_size_mappings ||= {
            'small' => {
              height: 400,
              label: "#{I18n.t("crm.form_integrator.height.small")} (400px)"
            },
            'medium' => {
              height: 600,
              label: "#{I18n.t("crm.form_integrator.height.medium")} (600px)"
            },
            'large' => {
              height: 800,
              label: "#{I18n.t("crm.form_integrator.height.large")} (800px)"
            }
          }
        end

        def render_style_controls
          DIV(class: 'mb-3 mt-4') do
            DIV(Class: 'row') do
              DIV(class: 'col-md-12') do
                DIV(class: 'form-group') do
                  TEXTAREA(
                    class: 'form-control',
                    rows: 2,
                    value: ::Form::Integrator::Store.loading_message_text
                  ).on(:input) do |e|
                    ::Form::Integrator::Store.update_settings({loading_message_text: e.target.value})
                    mutate
                  end
                end
              end
            end
            DIV(class: 'row') do
              DIV(class: 'col-md-12') do
                DIV(class: 'form-group') do
                  LABEL { I18n.t("crm.form_integrator.styles.font_size") }
                  DIV(class: 'd-flex align-items-center') do
                    INPUT(
                      type: 'range',
                      class: 'form-control-range flex-grow-1',
                      min: 10,
                      max: 20,
                      defaultValue: ::Form::Integrator::Store.code_font_size
                    ).on(:input) do |e|
                      ::Form::Integrator::Store.code_font_size = e.target.value.to_i
                      mutate
                    end
                    SPAN(class: 'ml-2 badge badge-secondary') {
                      "#{::Form::Integrator::Store.code_font_size}px"
                    }
                  end
                end
              end
            end
            DIV(class: 'row') do
              DIV(class: 'col-md-6') do
                DIV(class: 'form-group') do
                  LABEL { I18n.t("crm.form_integrator.styles.colors") }
                  render_color_input_with_sketch
                end
              end
              DIV(class: 'col-md-6') do
                DIV(class: 'form-group') do
                  LABEL(class: 'd-block') { I18n.t("crm.form_integrator.styles.text_style") }
                  DIV(class: 'btn-group') do
                    BUTTON(
                      class: "btn btn-outline-secondary #{::Form::Integrator::Store.code_bold ? 'active' : ''}",
                      type: 'button'
                    ) do
                      B { 'B' }
                    end.on(:click) do
                      ::Form::Integrator::Store.update_settings({code_bold: !::Form::Integrator::Store.code_bold})
                      mutate
                    end
                    BUTTON(
                      class: "btn btn-outline-secondary #{::Form::Integrator::Store.code_italic ? 'active' : ''}",
                      type: 'button'
                    ) do
                      I { 'I' }
                    end.on(:click) do
                      ::Form::Integrator::Store.update_settings({code_italic: !::Form::Integrator::Store.code_italic})
                      mutate
                    end
                  end
                end
              end
            end
          end
        end

        def render_color_input_with_sketch
          DIV(class: 'position-relative') do
            DIV(class: 'input-group') do
              DIV(class: 'input-group-prepend') do
                BUTTON(
                  type: :button,
                  class: 'btn btn-outline-secondary',
                  title: I18n.t("crm.form_integrator.styles.click_to_pick_color")
                ) do
                  I(
                    class: 'fas fa-square',
                    style: {
                      color: ::Form::Integrator::Store.code_color
                    }
                  )
                end.on(:click) do
                  @show_color_picker = !@show_color_picker
                  mutate
                end
              end
              INPUT(
                type: :text,
                class: 'form-control',
                value: ::Form::Integrator::Store.code_color,
                placeholder: '#000000'
              ).on(:change) do |e|
                ::Form::Integrator::Store.update_settings({code_color: e.target.value})
                mutate
              end
            end
            if @show_color_picker
              DIV(class: 'position-absolute top-0', style: {zIndex: '100' }) do
                render_sketch_color_picker
              end
            end
          end
        end

        def render_sketch_color_picker
          DIV(
            class: 'fixed-top fixed-bottom',
            style: { zIndex: '0' }
          ).on(:click) do
            @show_color_picker = false
            mutate
          end
          SketchPicker(
            color: ::Form::Integrator::Store.code_color
          ).on(:change) do |color, event|
            ::Form::Integrator::Store.update_settings({code_color: color.hex})
            mutate
          end
        end

        def render_code_section
          LABEL(class: "mt-4") { I18n.t("crm.form_integrator.iframe_code") }
          DIV(class: 'position-relative') do
            TEXTAREA(
              class: 'form-control mb-2',
              readOnly: true,
              rows: 7,
              value: iframe_code
            )

            render_expand_button
          end
        end

        def render_expand_button
          BUTTON(
            class: 'btn btn-outline-secondary btn-sm position-absolute m-1 py-1 px-2 rounded z-10',
            type: 'button',
            title: I18n.t("crm.form_integrator.preview_code"),
            style: {
              top: '8px',
              right: '8px',
            }
          ) do
            I(class: 'fa fa-expand')
          end.on(:click) do |e|
            e.prevent_default
            show_modal_requested!({
              title: I18n.t("crm.form_integrator.iframe_code"),
              text: render_code_preview_modal,
              cancel_text: I18n.t("crm.form_integrator.close"),
              type: :code_preview
            })
          end
        end

        def render_action_buttons
          DIV(class: 'd-flex mt-4') do
            render_preview_button
            render_copy_buttons
            render_height_selector
          end
        end

        def render_preview_button
          BUTTON(
            class: 'btn btn-outline-secondary mr-2',
            type: 'button',
            disabled: preview_url.blank?
          ) do
            I(class: 'fa fa-external-link-alt mr-1')
            SPAN { I18n.t("settings.schema.forms.goto_form") }
          end.on(:click) do |e|
            e.prevent_default
            preview_requested! if preview_url.present?
          end
        end

        def render_copy_buttons
          BUTTON(
            class: 'btn btn-outline-secondary mr-2',
            type: 'button',
            disabled: preview_url.blank?
          ) do
            I(class: 'fa fa-link mr-1')
            SPAN { I18n.t("crm.form_integrator.copy_iframe_link") }
          end.on(:click) do |e|
            e.prevent_default
            copy_link_requested!(preview_url) if preview_url.present?
          end

          BUTTON(
            class: 'btn btn-sm btn-outline-secondary mr-2',
            type: 'button',
            disabled: iframe_code.blank?
          ) do
            I(class: 'fa fa-copy mr-1')
            SPAN { I18n.t("crm.form_integrator.copy_iframe_code") }
          end.on(:click) do |e|
            e.prevent_default
            copy_code_requested!(iframe_code) if iframe_code.present?
          end
        end

        def render_height_selector
          SELECT(
            class: 'form-control ml-2 w-100',
            value: height_to_size(iframe_height)
          ) do
            iframe_size_mappings.each do |size, config|
              OPTION(value: size) { config[:label] }
            end
          end.on(:change) do |e|
            new_height = size_to_height(e.target.value)
            height_changed!(new_height) if new_height
          end
        end

        def render_modal
          modal_props = {
            id: 'form-integrator-modal',
            title: modal_params[:title],
            text: modal_params[:text],
            cancel_text: modal_params[:cancel_text]
          }

          ::Modal::Preview(modal_props).on(:close) do
            close_modal_requested!
          end
        end

        def render_code_preview_modal
          TEXTAREA(
            class: 'form-control',
            readOnly: true,
            rows: 30,
            value: iframe_code,
            id: 'modal-preview-code-textarea'
          )
        end

        def size_to_height(size)
          iframe_size_mappings[size]&.dig(:height)
        end

        def height_to_size(height)
          iframe_size_mappings.find { |_, config| config[:height] == height }&.first || 'medium'
        end
      end
    end
  end
end