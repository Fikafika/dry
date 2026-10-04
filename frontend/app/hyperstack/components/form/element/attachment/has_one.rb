# backtick_javascript: true

class Form
  module Element
    module Attachment
      class HasOne < Base
        include Hyperstack::Router::Helpers

        render { content }

        # input - input_file --------------------------------------------------------------------------

        def render_input
          send("render_input_#{editor || default_editor}")
        end

        def default_editor
          (attribute_name == klass.try(:photo_attachment)) ? 'photo' : 'input_file'
        end

        def has_mail_context?
          super && default_editor != 'photo'
        end

        def render_input_input_file
          layout_input do
            if @progress
              progress_bar(@progress)
              if upload_complete?
                after(min_progress_time) do
                  @progress = nil
                  mutate
                end
              end
            else
              if attached?
                attachment_btn(attachment)
              else
                browse_btn
              end
              input_file
            end
            fake_form_control_for_errors
            input_errors
            render_context_menu
          end.on(:context_menu) do |event|
            show_context_menu(event)
          end
        end

        def input_file
          INPUT(id: input_id, type: "file", class: 'p-0 m-0', style: {opacity: 0, width: 0, height: 0}, accept: input_file_accept) do
          end.on(:change) do |evt|
            remove_upload_errors
            attached.upload(`#{evt.target.to_n}.files`, assign: false).progress do |event|
              @progress = event
              mutate
            end.success do |attachment|
              change_value(attachment)
              @progress = nil
              mutate
            end.failure do |error, file|
              add_upload_error(error, file)
              @progress = nil
              mutate
            end
          end
        end

        def attached
          record.send(attribute_name)
        end

        def attached?
          return false unless form
          !!form.submission.read(path)
        end

        def detach(attachment)
          change_value(nil)
        end

        def change_data(value, record = self.record)
          form.submission.data[input_prefix] ||= {}
          form.submission.data[input_prefix][attribute_name] = value
        end

        def attachment
          data
        end

        def convert_value(value)
          if other_params[:serialize_value]
            return nil unless value.try(:signed_id)
            return {attachment: {signed_id: value.try(:signed_id), filename: value.try(:filename)}}
          else
            return value.try(:signed_id)
          end
        end

        def upload_complete?
          @progress.type == 'loadend'
        end

        # input - photo --------------------------------------------------------------------------

        def render_input_photo
          layout_input do
            if @progress
              progress_bar(@progress)
              if upload_complete?
                after(0.8) do
                  @progress = nil
                  mutate
                end
              end
            else
              photo_btn(attachment) do
                photo_download_icon
                input_detach_icon
              end
              input_file
            end
            input_errors
          end
        end

        def photo_download_icon
          return unless attached?
          A(href: attachment.download_path, target: '_blank', class: 'btn btn-light btn-sm position-absolute mr-5 mt-2', style: {top: 0, right: 0}) do
            I(class: 'fas fa-download') {}
          end.on(:click) do |event|
            event.stop_propagation
          end
        end

        def input_detach_icon
          return unless attached? && can_edit?
          A(href: '#detach', class: 'btn btn-light btn-sm position-absolute mr-3 mt-2', style: {top: 0, right: 0}) do
            I(class: "fas fa-trash") {}
          end.on(:click) do |event|
            event.stop_propagation
            change_value(nil)
          end
        end

        def photo_btn(attachment)
          DIV(class: can_edit? ? 'cursor-pointer hover-show-edit-icon' : '') do
            photo_tag(attachment, record&.class.try(:icon), class: 'photo-button')
            yield if block_given?
          end.on(:click) do |event|
            next if disabled_by_autocomplete || disabled || readonly
            event.stop_propagation
            input_file_element.click
          end
        end

        def input_file_element
          self.jq_node.find('input[type=file]')
        end

        # edit in place - input_file ----------------------------------------

        def render_edit_in_place
          send("render_edit_in_place_#{editor || default_editor}")
        end

        def render_edit_in_place_input_file
          layout_edit_in_place do
            edit_in_place_progress_or_input_file
            render_context_menu
          end.on(:context_menu) do |event|
            show_context_menu(event)
          end.on(:dragOver) do |event|
            event.prevent_default
            mutate @dragging_over = true
          end.on(:dragLeave) do
            mutate @dragging_over = false
          end.on(:drop) do |event|
            event.prevent_default
            @edit = true
            @dragging_over = false
            remove_upload_errors
            upload_file(`#{event.to_n}.nativeEvent.dataTransfer.files`)
            mutate
          end
        end

        def edit_in_place_progress_or_input_file
          if @progress
            DIV(class: 'form-control p-0') do
              progress_bar(@progress)
            end
          else
            edit_in_place_fake_input do
              edit_in_place_value_container do
                read_only_displayed_value&.on(:mouse_enter) do |event|
                  @mouse_hover_link = true
                  mutate
                end&.on(:mouse_leave) do |event|
                  @mouse_hover_link = false
                  mutate
                end
              end
            end.on(:click) do |event|
              event.prevent_default
              input_file_element.click
            end
            edit_in_place_input_file
          end
        end

        def edit_in_place_input_file
          INPUT(id: input_id, type: "file", class: 'p-0 m-0 float-left', style: {opacity: 0, width: 0, height: 0}, accept: input_file_accept) do
          end.on(:change) do |evt|
            upload_file(`#{evt.target.to_n}.files`)
          end
        end

        def upload_file(file)
          @previous_attachment = attached&.attachment if use_photo?

          attached.upload(file).progress do |event|
            @progress = event
            mutate
          end.success do
            @progress = nil

            record.save.then do |response|
              @success = response[:success]
              @progress = nil
              @loading = false
              if @success
                change_value(attached)
              else
                attached.attach(@previous_attachment) if use_photo? # revert
              end
              @success ? form.success!(response, form) : form.error!(response, form)
              mutate
            end

            mutate
          end.failure do |error|
            @progress = nil
            @success = false
            mutate
          end
        end

        def edit_in_place_icon
          super
          edit_in_place_detach_icon
          edit_in_place_download_icon
        end

        def edit_in_place_detach_icon
          return if @mouse_hover_link
          return unless attached.try(:attached?)
          I(class: "fas fa-trash edit-icon float-right cursor-pointer mr-4 mt-2", style: {top: 0, right: 0}).on(:click) do |event|
          end.on(:click) do |event|
            event.stop_propagation
            if requirement == 'mandatory'
              @success = false
              error = {error: :blank}
              form.error!(error)
              mutate
            else
              Modal.confirm(title: I18n.t('shared.delete')) do
                edit_in_place_detach
              end
            end
          end
        end

        def edit_in_place_download_icon
          return if @mouse_hover_link
          return unless attached.try(:attached?)
          A(href: attachment.download_path, target: '_blank', class: 'edit-icon float-right text-dark text-align-top cursor-pointer p-0 mt-2 mr-2', style: {lineHeight: 1, top: 0, right: 0}) do
            I(class: 'fas fa-download') {}
          end.on(:click) do |event|
            event.stop_propagation
          end
        end

        def edit_in_place_detach
          @loading = true
          @success = nil
          record.update(attribute_name => nil).then do |response|
            @success = response[:success]
            @loading = false
            if @success
              record.send(:"#{attribute_name}=", nil)
              change_value(nil)
            end
            @success ? form.success!(response, form) : form.error!(response, form)
            mutate
          end
          mutate
        end

        # edit in place - photo ----------------------------------------

        def render_edit_in_place_photo
          layout_edit_in_place do
            edit_in_place_progress_or_photo
          end
        end

        def edit_in_place_progress_or_photo
          if @progress
            DIV(class: 'form-control p-0') do
              progress_bar(@progress)
            end
          else
            photo_btn(attachment) do
              edit_in_place_input_file
              edit_in_place_icon
            end.on(:click) do |event|
              input_file_element.click
            end
          end
        end

        # read only ----------------------------------------------

        def read_only_displayed_value
          return unless attached&.attached?
          if use_photo?
            photo_tag(attachment, record&.class.try(:icon), class: 'photo-button')
          else
            A(href: attached.download_path, target: "_blank") do
              attached.filename
            end.on(:click) do |event|
              event.stop_propagation
            end
          end
        end

        def use_photo?
          (editor || default_editor) == 'photo'
        end

        # edit cell ----------------------------------------------

        def render_edit_cell
          try("render_edit_cell_#{editor || default_editor}")
        end

        def render_edit_cell_photo
          layout_edit_cell do
            edit_in_place_progress_or_photo
          end
        end

        def render_edit_cell_input_file
          layout_edit_cell do
            edit_in_place_progress_or_input_file
          end
        end

        # ---------------------------------------------------------

        def input_errors
          DIV(class: "d-none form-control #{invalid_css_class}") # hack to display invalid-feekback with bootstrap 4.3
          super
        end

      end
    end
  end
end
