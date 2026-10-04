# backtick_javascript: true

class Form
  module Element
    module Attachment
      class HasMany < Base
        include Hyperstack::Router::Helpers

        render { content }

        def render_input
          layout_input do
            attachments.each do |a|
              attachment_btn(a, {class: "mb-2"})
              BR{}
            end

            input_file
            progresses

            browse_btn unless uploading? || !can_edit?

            fake_form_control_for_errors
            input_errors
          end
        end

        def progresses
          @progresses&.values&.each do |progress|
            progress_bar(progress)
          end
        end

        def uploading?
          @progresses.try(:any?)
        end

        def input_file
          INPUT(id: input_id, type: "file", multiple: true, class: 'p-0 m-0 float-right', style: {opacity: 0, width: 0, height: 0}, accept: input_file_accept) do
          end.on(:change) do |evt|
            remove_upload_errors
            upload_files(`#{evt.target.to_n}.files`)
          end
        end

        def upload_files(files)
          attached.upload(files, assign: false).progress do |event|
            @progresses ||= {}
            @progresses[event.file] = event
            mutate
          end.success do |attachment|

            after(min_progress_time) do
              @progresses.delete(attachment.file)

              value = attachments.to_a

              i = nil
              if @attachment_to_replace
                i = value.index{|a| a.signed_id == @attachment_to_replace.signed_id }
              end

              if i
                value[i] = attachment
              else
                value << attachment
              end
              change_value(value)
              @attachment_to_replace = nil

              mutate

            end
          end.failure do |error, file|
            add_upload_error(error, file)
            mutate
          end
        end

        def browse_btn
          attachments.any? ? add_btn : super
        end

        def add_btn
          BUTTON(class: 'btn btn-light') do
            I18n.t("shared.add")
          end.on(:click) do |event|
            open_browse_dialog
          end
        end

        def attached
          record.send(attribute_name)
        end

        def detach(attachment)
          if form.submission.read(path).is_a?(Array)
            form.submission.read(path).delete_if do |signed_id|
              signed_id == attachment.signed_id
            end
          end
          if form.submission.data[input_prefix][attribute_name]
            form.submission.data[input_prefix][attribute_name].delete_if do |a|
              a.signed_id == attachment.signed_id
            end
          end
        end

        def attachments
          return [] unless form
          data || []
        end

        def convert_value(value)
          return value.attachments.map(&:signed_id) if value.is_a?(::HyperResource::ActiveStorage::Attached)
          return nil unless value.is_a?(Array)
          if other_params[:serialize_value]
            return { attachments: value.map{|a| {signed_id: a.try(:signed_id), filename: a.try(:filename)} }}
          else
            return value.map(&:signed_id)
          end
        end

        def change_data(value, record = self.record)
          form.submission.data[input_prefix] ||= {}
          if value.is_a?(::HyperResource::ActiveStorage::Attached)
            form.submission.data[input_prefix][attribute_name] = value.attachments
          elsif value.is_a?(Array)
            form.submission.data[input_prefix][attribute_name] = value
          end
        end

        # edit in place ----------------------------------------

        def render_edit_in_place
          layout_edit_in_place do
            if edit_in_place_editing?
              render_edit_in_place_editing
            else
              render_edit_in_place_not_editing
            end
            render_context_menu
          end.on(:context_menu) do |event|
            @context_data = data
            show_context_menu(event)
          end
        end

        def render_edit_in_place_editing
          attachments.each do |a|
            attachment_btn(a, {class: "mb-2"})
            BR{}
          end

          input_file
          progresses

          unless uploading?
            browse_btn
            close_btn
          end
        end

        def close_btn
          BUTTON(class: 'btn btn-light ml-2') do
            I18n.t("shared.finish")
          end.on(:click) do |event|
            value = form.submission.data[input_prefix][attribute_name]&.map{|a| a.signed_id}

            if requirement == 'mandatory' && !value&.any?
              # how revet to original value ?
              error = {error: :blank}
              form.error!(error)
              @success = false

              @edit = false
              mutate
            else
              @edit = false
              mutate

              record.attributes[attribute_name] = value

              @loading = true
              record.save.then do |response|
                @success = response[:success]
                @loading = false
                @success ? form.success!(response, form) : form.error!(response, form)
                mutate
              end

            end
          end
        end

        def render_edit_in_place_not_editing
          edit_in_place_fake_input do
            edit_in_place_value_container do
              empty_and_show_placeholder? ? placeholder : read_only_displayed_value
            end
          end.on(:click) do |event|
            event.prevent_default
            @edit = true
            mutate
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
            upload_files(`#{event.to_n}.nativeEvent.dataTransfer.files`)
            mutate
          end
        end

        def fake_input_css_class
          "#{super} h-100"
        end

        after_update do
          if mode == 'edit_in_place'
            if !@edit_was && @edit && attachments.empty?
              open_browse_dialog
            end
            @edit_was = @edit
          end
        end

        def edit_in_place_value_container
          yield
        end

        # read only ----------------------------------------------

        def read_only_displayed_value
          attached&.attachments&.each do |a|
            A(href: a.download_path, target: "_blank", class: "") do
              a.filename
            end.on(:click) do |event|
              event.stop_propagation
            end.on(:mouse_enter) do |event|
              @mouse_hover_link = true
              mutate
            end.on(:mouse_leave) do |event|
              @mouse_hover_link = false
              mutate
            end.on(:context_menu) do |event|
              event.stop_propagation
              @context_data = a
              show_context_menu(event)
            end
            render_context_menu
            BR{}
          end
        end

        # edit cell ----------------------------------------------

        def render_edit_cell
          render_edit_cell_input_file
        end

        def render_edit_cell_input_file
          layout_edit_cell do
            render_edit_in_place_editing
          end
        end

        # ---------------------------------------------------------

        def attachment_to_send
          @context_data ||= data
        end
      end
    end
  end
end
