class Form
  module Element
    module Control
      class Navigation < Base

        param :previous_button_text, default: nil
        param :next_button_text, default: nil
        param :cancel_button_text, default: nil
        param :save_as_draft_button_text, default: nil
        param :submit_button_text, default: nil

        param :show_previous_button, default: true
        param :show_next_button, default: true
        param :show_cancel_button, default: true
        param :show_save_as_draft_button, default: false
        param :show_submit_button, default: true

        param :buttons_automatically_shown, default: false
        param :show_submit_button_from_page_number, default: nil

        render { content }

        def render_input
          DIV(ref: _ref, class: 'row') do
            DIV(class: 'col') do
              ErrorMessage(form: form, timestamp: timestamp)
              if form.mode == :input
                DIV class: 'btn-toolbar justify-content-between pb-3' do
                  DIV do
                    children.render
                  end
                  DIV do
                    if buttons_automatically_shown
                      if form.page_count > 1
                        multiple_page_buttons
                      else
                        single_page_buttons
                      end
                    else
                      cancel_button
                      previous_button
                      next_button
                      save_as_draft_button
                      submit_button
                    end
                  end
                end
              end
            end
          end
        end

        def render_readonly
          stub # don't render
        end

        def render_edit_in_place
          stub # TODO like render_input but without submit
        end

        def multiple_page_buttons
          @page = nil
          previous_button
          submit_from_page = show_submit_button_from_page_number || form.page_count
          if page != form.page_count
            next_button
          end
          save_as_draft_button
          submit_button if page >= submit_from_page
        end

        def single_page_buttons
          cancel_button
          save_as_draft_button
          submit_button
        end

        def previous_button
          return unless show_previous_button
          previous_disabled = form&.submitting? || page <= 1
          BUTTON class: "btn btn-light ml-2 #{'disabled' if  previous_disabled} text-capitalize-first-letter" do
            previous_button_text || I18n.t('form.previous')
          end.on(:click) do |event|
            event.prevent_default
            form.go_to_previous_page
          end
        end

        def next_button
          return unless show_next_button
          BUTTON class: "btn btn-light ml-2" do
            SPAN(class: 'text-capitalize-first-letter') do
              next_button_text || I18n.t('form.next')
            end
            loading_icon
          end.on(:click) do |event|
            event.prevent_default
            form.go_to_next_page
          end
        end

        def submit_button
          return unless show_submit_button
          BUTTON class: "btn btn-primary ml-2 #{'disabled' if disabled?}" do
            SPAN(class: 'text-capitalize-first-letter') do
              submit_button_text || I18n.t('form.submit')
            end
            loading_icon
          end.on(:click) do |event|
            event.prevent_default
            if !disabled?
              form.submit.then do
                form.go_to_next_page unless form.submission.errors.any?
              end
            end
          end
        end

        def cancel_button
          return unless show_cancel_button
          BUTTON class: "btn btn-light #{'disabled' if disabled?} text-capitalize-first-letter" do
            cancel_button_text || I18n.t('form.cancel')
          end.on(:click) do |event|
            event.prevent_default
            form.cancel if form&.enabled?
          end
        end

        def save_as_draft_button
          return unless show_save_as_draft_button
          return unless form&.dynamic_form
          BUTTON class: "btn btn-light ml-2 #{'disabled' if disabled?}" do
            SPAN(class: 'text-capitalize-first-letter') do
              save_as_draft_button_text || I18n.t('form.save_as_draft')
            end
            loading_icon
          end.on(:click) do |event|
            event.prevent_default
            form.save_as_draft if form&.enabled?
          end
        end

        def disabled?
          !form&.enabled? || form&.submitting?
        end

        def loading_icon
          if form.submitting?
            after(2) do
              if !@show_loader && form.submitting?
                @show_loader = true
                force_update!
              end
            end

            if @show_loader
              I(class: 'ml-2 fa fa-spinner fa-pulse')
            end
          else
            @show_loader = false
          end
        end

        def page
          return @page if @page
          if in_editor
            @page = form.page_of(other_params[:id])
          else
            @page = form.submission.page
          end
        end

        def self.default_values
          {
            show_previous_button: true,
            show_next_button: true,
            show_cancel_button: true,
            show_submit_button: true,
          }
        end

      end
    end
  end
end
