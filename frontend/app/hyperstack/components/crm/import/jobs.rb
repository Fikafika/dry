class Crm
  class Import
    class Jobs < Base
      include ::Crm::CrmLayout

      render do
        content if schema.constants_loaded?
      end

      def content
        layout_with_toolbar(class: 'overflow-auto pb-5') do
          subscribe
          job&.children&.each do |j|
            next unless j.is_a?(Dynamic::Import::Job::ImportFile) # we currently only render this type of job
            job_logs(j)
          end
        end
      end

      def job
        observe Dynamic::Import::Job::Init.includes(job_includes).where(
          schema_id: request.params[:schema_id],
          setting_id: request.params[:import_setting_id]
        ).find(request.params[:job_id])
      end

      def job_includes
        {
          include: {
            children: {
              include: {
                source: {
                  include: {
                    csv: {
                      include: {
                        attachment: {
                          include: {
                            signed_id: 1,
                            filename: 1,
                            blob: {
                              include: {
                                signed_id: 1,
                                filename: 1,
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                },
                log_success_count: 1,
                log_warning_count: 1,
                log_error_count: 1,
                log_system_count: 1,
                setting: {
                  only: ['name','id']
                }
              }
            }
          }
        }
      end

      def global_toolbar_title
        DIV(class: 'col-8') do
          back_button
        end
      end

      def global_toolbar_menu_items
        GroupDrop(variant: 'primary') do
          group_buttons
        end
      end

      def group_buttons
        if false && !job.nil? && job.state != "finished"
          Toolbar::Button(text: I18n.t('shared.stop'), icon: 'stop', is_flex: true).on(:click) do |event|
            event.prevent_default
            puts "TODO: cancel running job"
          end
        end
      end

      def job_logs(job)

        return unless job

        DIV(class: "container-fluid") do

          DIV(class: "d-flex flex-row mt-3") do
            H4 do
              I18n.t("crm.import.settings.job.state") + " : " + job.human_attribute_value(:state)
            end
          end

          DIV(class: "d-flex flex-row ml-3") do
            DIV(class: "flex-column") do
              DIV do
                I18n.t('crm.import.settings.table.name') + ' : '
              end
              DIV do
                I18n.t("crm.import.settings.table.file") + " :"
              end
              DIV do
                I18n.t("crm.import.settings.import_lines") + " :"
              end
              DIV do
                I18n.t("crm.import.settings.import_state") + " :"
              end
              DIV do
                I18n.t("crm.import.settings.job.ordered") + " :"
              end
              DIV do
                I18n.t("crm.import.settings.job.modified") + " :"
              end
            end

            DIV(class: "flex-column ml-3") do
              DIV do
                job.setting.name
              end
              DIV do
                A(href: job.source.csv.download_path) do
                  I(class:"fa fa-download")
                  SPAN(class: "ml-1") do
                    job.source.name
                  end
                end
              end
              DIV do
                (job.lines_to_process || 0).to_s
              end
              DIV do
                job.lines_to_process || 0 > 0 ? (job.current_line || 0).to_s + '/' + (job.lines_to_process || 0).to_s : (job.current_line || 0).to_s
              end
              DIV do
                moment_format_value(job.created_at)
              end
              DIV do
                moment_format_value(job.updated_at)
              end
            end
          end
          DIV(class:"mt-4 text-center") do
            DIV(class:"d-flex flex-nowrap justify-content-start") do
              BUTTON(class:"btn rounded-0 border-0 m-0 text-break p-2 btn-primary") do
                I18n.t("shared.previous")
              end.on(:click) do |event|
                event.prevent_default
                App.history.push(edit_url(job.setting_id))
              end
            end
          end

          DIV(class: "d-flex flex-row mt-4") do
            line_count = nil # TODO it is impossible to predict how many records will be saved. job.logs.count is not appropriate because one line can have several logs. Approximate with number of lines in the source.
            H4 do
              I18n.t("crm.import.settings.job.import")+" #{line_count} #{job.source.klass_name&.safe_constantize&.model_name&.human(count: 2)&.downcase}"
            end
          end

          log_list(job, ['Dynamic::Import::Log::Error', 'Dynamic::Import::Log::System'], 'text-danger', job.log_error_count + job.log_system_count)
          log_list(job, 'Dynamic::Import::Log::Warning', 'text-warning', job.log_warning_count)
          log_list(job, 'Dynamic::Import::Log::Success', 'text-success', job.log_success_count)
          log_list(job, 'Dynamic::Import::Log::Warning', 'text-info', job.log_warning_count)

        end
      end

      def log_list(job, type, color, count)
        count = 0 unless count
        t = type.is_a?(Array) ? type.first : type
        category_title = (color == "text-info") ? 'unchanged' : t.demodulize.underscore
        DIV(class: "d-flex flex-row align-items-center") do
          A(class:"btn btn-transparent-light-yiq shadow-none ml-1 w-100 text-left", type: "button", "data-toggle": "collapse", "data-target": "##{t.gsub(/[:]/,'') + color}", "aria-expanded": "true") do
            I(class: "fa fa-fw fa-chevron-right pr-2 collapse-icon")
            SPAN(class: "#{color}") do
              I18n.t("crm.import.settings.job.logs.#{category_title}") + (category_title != 'unchanged' ? " : " + count.to_s : '')
            end
          end.on(:click) do |event|
            event.prevent_default
            ::Element[event.current_target.to_n].find('.collapse-icon').toggle_class('fa-chevron-down fa-chevron-right')
          end
        end

        if count > 0
          logs = job.logs.includes(row: 1)
          logs.scope[:where].delete(:parent_id) # TODO why job.parent_id is propagated in logs scope ?
          DIV(class: "collapse ", id: "#{t.gsub(/[:]/,'') + color}") do
            InfiniteScroll(DIV, class: 'my-2 overflow-auto', style: {maxHeight: '1000px'}, items: logs.merge_where(type: type)) do |log|
              next unless should_process_log?(log, category_title == 'unchanged')
              render_log(log)
            end
          end
        end
      end

      def subscribe
        return unless job&.loaded?
        return if @subscribed
        @subscribed = true
        @cable = job.children.__cable__
        @cable.subscribe do
          reload
        end
      end

      def unsubscribe
        return unless @subscribed
        @cable.unsubscribe
        @subscribed = false
      end

      before_unmount do
        unsubscribe
      end

      def reload
        job.reload do
          mutate
        end
      end

      def error_messages(log)
        log.messages.each do |m|
          message_klass = m.key?("klass") ? m['klass'] : log.instance_type
          DIV(class: "text-break") do
            if m['error'] && message_klass && m['attr']
              klass = message_klass.safe_constantize

              if klass
                SPAN do
                  klass.model_name.human
                end
                chevron
              end

              attr_or_assoc = nil
              path = m['attr'].split('.')
              path.each_with_index do |p, i|
                next unless klass
                attr_or_assoc = p.gsub(/\[\d+\]/, '') # display value of [\d+] ?
                SPAN do
                  klass.human_attribute_name(attr_or_assoc)
                end
                if i != path.length - 1
                  assoc_klass = klass.reflect_on_association(attr_or_assoc)&.klass
                  klass = assoc_klass if assoc_klass
                end
                chevron
              end

              SPAN do
                if klass && attr_or_assoc
                  "#{m['value']} #{I18n.error({error: m['error']}, klass, attr_or_assoc)}"
                else
                  "#{m['value']} #{m['error']}"
                end
              end
            elsif m['message']
              if m['message'] == 'unchanged'
                if klass_names.include?(message_klass)
                  DIV do
                    I18n.t("crm.import.settings.job.message.#{m['message']}", default: m['message'])
                  end
                end
              else
                I18n.t("crm.import.settings.job.message.#{m['message']}", default: m['message'])
              end
            end
          end
        end
      end

      def chevron
        I(class: 'fas fa-chevron-right px-2'){}
      end

      def should_process_log?(log, filter)
        if filter
          log.messages.any? { |msg| msg['message'] == 'unchanged' }
        else
          log.messages.any? { |msg| msg['message'] != 'unchanged' } || log.messages.empty?
        end
      end

      def render_log(log)
        DIV(class: "d-flex flex-row") do
          DIV(class: "col-auto") do
            I18n.t("crm.import.settings.job.logs.line") + " #{log.line} :"
          end
          DIV(class: "flex-fill") do
            if klass_names.include?(log.instance_type)
              A(href: record_query_url(log), target: '_blank', rel: 'noopener noreferrer') do
                log.instance_type&.constantize.model_name&.human.capitalize
              end
            end
            SPAN(class: 'ml-2') do
              "(#{log.row.join(', ')})"
            end
            DIV(class: 'text-muted') do
              if log.type == "Dynamic::Import::Log::System"
                SPAN do
                  I18n.t('crm.import.settings.job.logs.system_error')
                end
                if Hyperstack.env == 'development'
                  I(class: "fa fa-question-circle ml-2", title: "#{log.messages.map { |m| m['message'] }}")
                end
              else
                error_messages(log)
              end
            end
          end
        end
      end

      def klass_names
        @klass_names ||= schema.klasses.map(&:const_absolute_name)
      end

      def index_url
        return interpolate_path("/crm/:schema_id/import_settings", {
          schema_id: request.params[:schema_id]
        })
      end

      def edit_url(id)
        "#{index_url}/#{id}/edit"
      end

      def index_url_record(klass)
        return unless request
        return interpolate_path("/crm/:schema/:mode/:klass", {
          schema: request.params[:schema] || request.params[:schema_id],
          klass: klass.model_name.route_key,
          mode: request.params[:mode] || 'table',
        })
      end

      def record_query_url(log)
        instance_klass = log.instance_type.safe_constantize
        query = {
          rp: url_for(action: 'edit', id: log.instance_id, klass: instance_klass),
        }
        return index_url_record(instance_klass) unless query.any?
        return "#{index_url_record(instance_klass)}/last_search?#{encode_url_params(query)}"
      end

    end
  end
end
