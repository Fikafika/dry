class Crm
  class Import
    module Step
      class LaunchImport < Base

        before_render do
          initialize_errors
          initialize_values if setting.loaded?
        end

        render do
          content if setting.loaded?
        end

        def content
          DIV do
            DIV(class: 'd-flex flex-row pt-5 mt-5') do
              DIV(class: 'flex-column') do
                DIV do
                  I18n.t('crm.import.settings.table.name') + ' : '
                end
                DIV do
                  I18n.t('crm.import.settings.table.file') + ' : '
                end
              end
              DIV(class: 'flex-column ml-3') do
                DIV do
                  setting.name
                end
                DIV do
                  if source.try(:csv)&.attached?
                    A(href: source.csv.download_path) do
                      I(class:'fa fa-download')
                      SPAN(class: 'ml-1') do
                        source.name
                      end
                    end
                  else
                    I18n.t('crm.import.settings.no_file')
                  end
                end
              end
            end
            DIV(class: 'd-flex flex-column mt-3') do
              H4() do
                SPAN() do
                  I18n.t('crm.import.settings.plan_import')
                end
              end
              DIV(class: 'form-group') do
                LABEL() { I18n.t("crm.import.settings.launch.label_starting_line").to_s }
                INPUT(
                  type: 'number',
                  value: @current_line,
                  class: 'col-12 form-control'
                ).on(:change) do |e|
                  handle_change(e.target.value, "current_line")
                  mutate
                end
                if @error[:current_line]
                  SPAN(class: 'text-danger') { I18n.t("shared.required").to_s }
                end
                if @error[:current_line_negative]
                  SPAN(class: 'text-danger') { I18n.t("crm.import.settings.launch.negative_value_error").to_s }
                end
              end
              DIV(class: 'form-group') do
                LABEL() { I18n.t("crm.import.settings.launch.label_end_line").to_s }
                INPUT(
                  type: 'number',
                  value: @end_line,
                  class: 'col-12 form-control',
                ).on(:change) do |e|
                  handle_change(e.target.value, "end_line")
                  mutate
                end
                if @error[:end_line_negative]
                  SPAN(class: 'text-danger') { I18n.t("crm.import.settings.launch.negative_value_error").to_s }
                elsif @error[:end_line_length]
                  SPAN(class: 'text-danger') { I18n.t("crm.import.settings.launch.end_line_length_error").to_s }
                end
              end
              if @lines_to_process&.positive?
                DIV() do
                  SPAN() { "#{I18n.t('crm.import.settings.import_lines')} : #{@lines_to_process}" }
                end
              end
            end
            footer
          end
        end

        def update_lines_to_process
          @lines_to_process = if @current_line && @end_line
            start_line = source.has_title_line? ? 2 : 1
            @end_line + 1 - (@current_line < start_line ? start_line : @current_line)
          else
            0
          end
        end

        def process_save_button(event)
          return if @error.values.any?
          @saving = true
          mutate @requesting_save = true
          save_job.then do |result|
            if result[:success]
              @saving = false
              @requesting_save = false
              mutate
            end
          end
        end

        def process_save_and_next_button(event)
          @saving = true
          mutate @requesting_save_and_next = true
          return if @error.values.any?
          save_job.then do |result|
            if result[:success]
              job.setting.process_all.then do |response|
                @requesting_save_and_next = false
                mutate @saving = false
                if response[:success]
                  setting.reload do
                    App.history.push(last_init_job_url(setting))
                  end
                else
                  @resp = response
                  mutate
                end
              end
            end
          end
        end

        def setting_error_message
          super
          launch_error_message
        end

        def launch_error_message
          DIV(class: "row mt-2 justify-content-end") do
            if @resp
              if @resp['success'] == false
                message = @resp['errors']['message']
                return unless message.is_a?(String)
                DIV class: 'alert alert-danger', role: 'alert' do
                  message == 'error' ? I18n.t("shared.error") : message
                end
              end
            end
          end
        end

        def initialize_errors
          @error ||= { current_line: false, current_line_negative: false, end_line_negative: false, end_line_length: false }
        end

        def validate_job
          @error = {}
          @error[:current_line] = @current_line.nil? && !@end_line.nil?
          @error[:end_line_length] = !@end_line.nil? && !@current_line.nil? && @end_line < @current_line
          @error[:current_line_negative] = @current_line&.negative?
          @error[:end_line_negative] = @end_line&.negative?
          return @error.values.any? ? true : false
        end

        def fetch_job
          setting.jobs.select { |job| job.type == "Dynamic::Import::Job::Init" && job.state != "finished" && job.state != "in_progress" }.last ||
          setting.jobs.new(type: 'Dynamic::Import::Job::Init', current_line: nil, lines_to_process: nil)
        end

        def job
          @job ||= fetch_job
          return @job
        end

        def source
          setting.output
        end

        def setting_includes
          {
            include: {
              jobs: 1,
              output: {
                include: {
                  csv: csv_includes,
                }
              },
            },
          }
        end

        def initialize_values
          return if @values_initialized
          transform_attribute_for_display
          @end_line = job.current_line && job.lines_to_process ? job.current_line + job.lines_to_process : nil
          @values_initialized = true
        end

        def save_job
          transform_attribute_for_save
          return job.save
        end

        def transform_attribute_for_display
          if job.id.present?
            @current_line = job.current_line ? job.current_line + 1 : job.current_line
            @lines_to_process = job.lines_to_process
          end
        end

        def transform_attribute_for_save
          job.current_line = @current_line && @current_line > 0 ? @current_line - 1 : @current_line
          job.lines_to_process = if @current_line && @end_line
            start_line = source.has_title_line? ? 2 : 1
            @end_line + 1 - (@current_line < start_line ? start_line : @current_line)
          else
            nil
          end
        end

        def handle_change(value, type)
          value = value.empty? ? nil : value.to_i
          instance_variable_set("@#{type}", value)
          update_lines_to_process
          validate_job
        end
      end
    end
  end
end
