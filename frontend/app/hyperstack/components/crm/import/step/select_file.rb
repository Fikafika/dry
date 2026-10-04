# backtick_javascript: true

class Crm
  class Import
    module Step
      class SelectFile < Base

        render do
          content if setting.new_record? || setting.loaded?
        end

        def content
          DIV(class: "d-flex flex-lg-row flex-column-reverse mt-5") do
            DIV(class: "col p-0") do
              H4(class: 'mt-3') do
                I18n.t('crm.import.settings.advanced_params.definition')
              end
              DIV(class: 'form-group') do
                LABEL do
                  I18n.t("shared.file")
                end
                DIV do
                  browse_btn
                end
              end
              DIV(class: 'form-group') do
                LABEL do
                  I18n.t('crm.import.settings.table.name')
                end
                INPUT(type: 'text', class: 'form-control w-auto', placeholder: I18n.t('crm.import.settings.name_placeholder'), name: '', value: setting.name) do
                end.on(:change) do |evt|
                  mutate setting.attributes[:name] = evt.target.value
                end
              end
            end
          end
          footer
        end

        def setting_includes
          {
            sources: {
              include: {
                csv: csv_includes,
              },
            },
          }
        end

        def setting
          super
          if (@setting.new_record? || @setting.loaded?) && @setting.sources&.empty?
            @setting.sources.new(type: 'Dynamic::Import::Source::Csv')
          end
          return @setting
        end

        def browse_btn
          unless @progress
            DIV(class: 'btn-group') do
              BUTTON(class: 'btn btn-light') do
                if source.try(:csv)&.attached?
                  source.csv.filename
                else
                  I18n.t("shared.browse")
                end
              end.on(:click) do |evt|
                ::Element.find('#input-file').click
              end

              if source.try(:csv)&.attached?
                Link("", class: 'btn btn-light') do
                  I(class: 'fas fa-trash') do
                  end
                end.on(:click) do |event|
                  event.prevent_default
                  source.csv.detach
                  mutate
                end
              end
            end

            INPUT(id: "input-file", type: "file", accept: ".csv", class: 'p-0 m-0', style: {opacity: 0, width: 0, height: 0}) do
            end.on(:change) do |evt|
              files = `#{evt.target.to_n}.files`
              file = files ? `files[0]` : nil

              source.csv.upload(file).progress do |event|
                @progress = event
                @upload_error = nil
                mutate
              end.success do
                @upload_error = nil
                @progress = nil
                if setting.name.blank?
                  csv_name = source.csv.filename.split('.')
                  setting.name = csv_name[0].gsub(/[^0-9A-Za-z]/, ' ').squeeze(' ').strip
                end
                mutate
              end.failure do |error|
                @progress = nil
                @upload_error = error
                mutate
              end
            end

            if @upload_error
              DIV(class: 'alert alert-danger mt-2') do
                @upload_error
              end
            end
          else
            DIV(class: 'd-flex') do
              ProgressBar(event: @progress, class: 'flex-grow-1 align-self-center') do
              end
              Link("", class: 'btn btn-transparent-light-yiq btn-sm align-self-center', style: {opacity: @progress.type == 'loadend' ? 0 : 1 }) do
                I(class: 'fas fa-times', style: {'verticalAlign': 'text-bottom' }) do
                end
              end.on(:click) do |event|
                event.prevent_default
                source.csv.detach
                mutate
              end
            end

            if @progress.type == 'loadend'
              after(0.8) do
                @progress = nil
                mutate
              end
            end
          end
        end
      end
    end
  end
end
