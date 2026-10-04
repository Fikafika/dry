class Form
  module Element
    module Attachment
      class Base < ::Form::Element::Base

        include Crm::MailDropdown

        render { content }

        def klass
          other_params[:klass] || record&.class
        end

        # input ------------------------------------------------

        def render_input
        end

        def empty_and_show_placeholder?
          data.blank?
        end

        def attachment_btn(attachment, options = {})
          DIV(class: "btn-group #{options[:class]} #{'border border-danger' if attachment_is_invalid?(attachment)} #{'disabled' unless can_edit?}") do
            BUTTON(class: 'btn btn-light') do
              attachment.filename
            end.on(:click) do |event|
              next unless can_edit?
              @attachment_to_replace = attachment
              open_browse_dialog
            end
            A(href: attachment.download_path, target: '_blank', class: 'btn btn-light') do
              I(class: 'fas fa-download') do
              end
            end
            if can_edit?
              A(href: "#remove", class: 'btn btn-light') do
                I(class: 'fas fa-trash') do
                end
              end.on(:click) do |event|
                event.prevent_default
                detach(attachment)
                mutate
              end
            end
          end
        end

        def attachment_is_invalid?(attachment)
          record_is_invalid? && record&.errors.try(:[], attribute_name)&.detect{|e| e['filename'] == attachment.filename}
        end

        def open_browse_dialog
          ::Element.find(input_css_id).click
        end

        def browse_btn
          BUTTON(class: "btn btn-light #{'border-danger' if record_is_invalid?}") do
            I18n.t("shared.browse")
          end.on(:click) do |event|
            open_browse_dialog
          end
        end

        def add_upload_error(error, file)
          if record
            record.errors ||= {}
            record.errors[attribute_name] ||= []
            record.errors[attribute_name] << { error: 'upload_failure', filename: file.name }
          end
        end

        def remove_upload_errors
          return unless record&.errors.try(:[], attribute_name)
          record.errors[attribute_name].delete_if{|e| e[:error] == 'upload_failure'}
        end

        def min_progress_time
          0.8
        end

        def render_input_hidden
          if in_editor
            layout_input_hidden do
            end
          end
        end

        def input_file_accept
          v = input_file_extensions
          return unless v&.any?
          input_file_extensions.map{|v| ".#{v}"}.join(',')
        end

        def input_file_extensions
          klass&.reflect_on_attachment(attribute_name)&.options&.[]('extensions')
        end

        def fake_form_control_for_errors
          return unless record_is_invalid?
          DIV(class: "form-control d-none #{invalid_css_class}")
        end

        def can_edit?
          !(disabled_by_autocomplete || disabled || readonly)
        end

        # edit in place ----------------------------------------

        def edit_in_place_fake_input
          DIV(class: fake_input_css_class) do
            yield
            edit_in_place_icon
          end
        end

        def fake_input_css_class
          "form-control #{css_classes&.dig(:field_size)} px-0 cursor-text bg-transparent #{'drag-over' if @dragging_over}"
        end

        # ------------------------------------------------------

        def progress_bar(progress)
          return unless progress
          DIV(class: 'd-flex flex-wrap') do
            if progress.file&.name
              DIV(class: 'text-truncate align-self-center pr-2', style: {width: '50%', maxWidth: '50%'}) do
                progress.file.name
              end
            end
            ProgressBar(event: progress, class: 'flex-grow-1 align-self-center') do
            end
            cancel_btn(progress)
          end
        end

        def cancel_btn(progress)
          finished = (progress.type == 'loadend')
          unless finished
            A(href: "#cancel", class: 'btn btn-transparent-light btn-sm align-self-center') do
              I(class: 'fas fa-times', style: {'verticalAlign': 'text-bottom' }) do
              end
            end.on(:click) do |event|
              event.prevent_default
              cancel_upload(progress)
              mutate
            end
          else
            # fake btn with same size
            DIV(class: 'btn btn-transparent-light btn-sm align-self-center', style: {opacity: 0 }) do
              I(class: 'fas fa-times', style: {'verticalAlign': 'text-bottom' }) do
              end
            end
          end
        end

        def cancel_upload(progress)
          # TODO
        end

        # cell ----------------------------------------------------------------

        def render_edit_cell
          layout_edit_cell do
            render_edit_in_place # TODO a specific mode
          end
        end

        # context menu --------------------------------------------------------

        def render_context_menu
          if context_menu_position && has_context_menu?
            ContextMenu(position: context_menu_position, css_position: 'fixed') do
              dropdown_item_for_mail_hosting_default_association(record) do
                Crm::MailEditor.add_attachments(attachment_to_send)
              end
            end.on(:hidden) do
              mutate @context_menu_position = nil
            end
          end
        end

        def attachment_to_send
          data
        end

        def context_menu_position
          observe @context_menu_position
        end

        def show_context_menu(event)
          return if event.ctrl_key

          event.prevent_default

          mutate @context_menu_position = ({x: event.client_x, y: event.client_y})
        end

        def has_context_menu?
          has_mail_context?
        end

        def data
          return unless form
          form.submission.data.dig(input_prefix, attribute_name)
        end

        def has_mail_context?
          record.class.parent.feature_enabled?('Dynamic::MailHosting::Feature') && record.class.has_mailhosting_associations? && respond_to?(:attached) && attached.attached?
        end
      end
    end
  end
end
