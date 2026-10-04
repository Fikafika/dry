class Crm
  class Import
    module Step
      class RenderImports < Base

        render { content }

        def content
          DIV(class: "d-flex flex-column") do
            DIV(class: "d-flex flex-row row m-3 align-items-center justify-content-end") do
              LABEL(class: 'mr-3 mb-0') { I18n.t("crm.import.settings.filter_title")}
              DIV(class: 'mr-3 d-inline dropdown') do
                A(href:"#", class: "btn btn-light dropdown-toggle border rounded-sm", 'data-toggle': 'dropdown', id: 'dropdown-class') do
                  @current_class.nil? ? I18n.t("shared.select") : @current_class.constantize.model_name.human(count: 2)
                end
                DIV(class: 'border rounded-0 shadow dropdown-menu container') do
                  klasses.each do |k|
                    A(href: '#', class: 'dropdown-item', value: k.model_name.human(count: 2)) do
                      k.model_name.human(count: 2)
                    end.on(:click) do |evt|
                      evt.prevent_default
                      @current_class = k.to_s
                      @settings = setting_scope.all { mutate }
                    end
                  end
                end
              end
              BUTTON(class: "btn btn-secondary") do
                I18n.t("crm.reset_filters")
              end.on(:click) do
                cancel_filter
                @settings = setting_scope.all { mutate }
              end
            end
            DIV(class: "d-flex flex-row row") do
              DIV(class:"table-responsive") do
                TABLE(class:"table table w-100") do
                  THEAD() do
                    header_row
                  end
                  TBODY() do
                    settings.each do |set|
                      if set.jobs.empty?
                        file = set.sources.first.original_csv
                        setting_row(set, file: file)
                      else
                        setting_row_with_jobs(set)
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def settings
          @settings ||= setting_scope.all { mutate }
        end

        def klasses
          schema.klasses.sort_by{|k| k.human_name}.map(&:const)
        end

        def setting_row(set, job: nil, file: nil, has_jobs: false)
          TR() do
            TD(class: "align-middle") do
              if has_jobs
                BUTTON(class:"btn btn-transparent-light-yiq shadow-none", type: "button", 'data-toggle': 'collapse', 'data-target': "#extended_jobs_#{set.id}") do
                  I(class: "fa fa-chevron-right fa-fw collapse-icon")
                end.on(:click) do |event|
                  event.prevent_default
                  ::Element[event.current_target.to_n].find('.collapse-icon').toggle_class('fa-chevron-right fa-chevron-down')
                end
              end
            end
            TD() do
              Link(edit_url(set.id), class:"btn bg-light", title: I18n.t("shared.edit"), data: { bs_toggle: "tooltip", bs_placement: "bottom" }) do
                set.name
              end
            end
            TD(class: "align-middle") do
              set.sources.sort_by{|s| s.created_at }.last&.klass_name&.constantize&.model_name&.human(count: 2)
            end
            TD(class: "align-middle") do
              moment_format_value(set.created_at)
            end
            TD(class: "align-middle") do
              moment_format_value(job.updated_at) if job
            end
            TD(class: "align-middle", style: { flex: '1 1 auto', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }) do
              file&.filename&.truncate(25)
            end
            TD() do
              if job
                Link(job_url(set.id, job.id), class:"btn bg-light", title: I18n.t("crm.import.settings.status_tooltip_title"), data: { bs_toggle: "tooltip", bs_placement: "bottom" }) do
                  job.human_attribute_value(:state)
                end
              else
                I18n.t("crm.import.settings.no_import")
              end
            end
            TD() do
              action_list(set, file)
            end
          end
        end

        def setting_row_with_jobs(set)
          import_jobs = set.jobs.select{|j| j.type == "Dynamic::Import::Job::Init"}
          import_jobs.sort_by{|k| k.created_at }.reverse!.each_with_index do |job, i|
            if i == 0
              file = job.source.original_csv
              setting_row(set, job: job, file: file, has_jobs: import_jobs.size > 1)
            elsif i.between?(1, 4)
              job_row(set, job)
            end
          end
        end

        def action_list(set, file)
          DIV(class: 'd-flex flex-row') do
            Link("#{edit_url(set.id)}",title: I18n.t("shared.edit"), class:"dropdown-item d-flex align-items-center justify-content-center", type: "button", style: {width: "20px"}) do
              I(class: "fas fa-pencil-alt")
            end
            A(class: 'dropdown-item d-flex align-items-center justify-content-center', title: I18n.t("shared.download"), type: "button", href: file&.download_path, style: {width: "20px"}) do
              I(class:"fa fa-download")
            end
            DIV(class: 'd-inline dropdown') do
              BUTTON(class: "btn btn-transparent-light-yiq shadow-none", type: "button", 'data-toggle': 'dropdown') do
                I(class:"fa fa-ellipsis-v")
              end
              DIV(class: 'dropdown-menu p-0', style: {'minWidth': '60px'}) do # TODO: CSS
                A(class: 'dropdown-item',title: I18n.t("shared.duplicate"), type: "button") do
                  I(class:"fa fa-clone")
                end.on(:click) do
                  set.duplicate.then do |response|
                    if response[:success]
                      @settings.stale!
                      mutate @settings = nil
                    else
                      Modal.confirm(
                        title: I18n.t('shared.error'),
                        text: I18n.errors_message(set, response[:errors]),
                        cancelClass:'d-none',
                        commit: 'Ok'
                      ){}
                    end
                  end
                end
                A(class: 'dropdown-item', title: I18n.t("shared.delete"), type: "button") do
                  I(class:"fa fa-trash")
                end.on(:click) do
                  Modal.confirm(title: I18n.t('shared.delete')) do
                    set.destroy.then do |response|
                      if response[:success]
                        mutate @settings = nil
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def job_row(set, job)
          file = job.source.original_csv
          TR(class:"collapse", id:"extended_jobs_#{set.id}") do
            TD() do
              # collapse
            end
            TD(class: "") do
              # collapse
            end
            TD(class: "") do
              # collapse
            end
            TD(class: "") do
              DIV(class:"d-flex flex-column") do
                SPAN() do
                  "#{I18n.t("crm.import.settings.launch.label_starting_line")} : #{job.current_line}"
                end
                SPAN() do
                  "#{I18n.t("crm.import.settings.launch.label_end_line")} : #{job.lines_to_process}"
                end
              end
            end
            TD(class: "align-middle") do
              moment_format_value(job.updated_at)
            end
            TD(class: "align-middle", style: { flex: '1 1 auto', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }) do
              job.source.name&.truncate(25)
            end
            TD(class: "") do
              Link(job_url(set.id, job.id), class:"btn bg-light") do
                job.human_attribute_value(:state)
              end
            end
            TD(class: "align-middle") do
              A(class: 'dropdown-item d-flex align-items-center justify-content-center', title: I18n.t("shared.download"), type: "button", href: file&.download_path, style: {width: "20px"}) do
                I(class:"fa fa-download")
              end
            end
          end
        end

        def header_row
          TR(class:"text-start") do
            TH() do
              # collapse
            end
            TH() do
              I18n.t("crm.import.settings.table.name")
            end
            TH() do
              I18n.t("crm.import.settings.table.type")
            end
            TH(class: "cursor-pointer") do
              DIV(class: 'd-flex align-items-center') do
                I(class: sort_icon_class(@created_at_sort))
                SPAN { I18n.t("crm.import.settings.table.creation") }
              end
            end.on(:click) do
              toggle_sort(:created_at, :@created_at_sort)
              mutate
            end
            TH(class: "cursor-pointer") do
              DIV(class: 'd-flex align-items-center') do
                I(class: sort_icon_class(@import_date_sort))
                SPAN { I18n.t("crm.import.settings.table.date") }
              end
            end.on(:click) do
              toggle_sort(:updated_at, :@import_date_sort)
              mutate
            end
            TH() do
              I18n.t("crm.import.settings.table.file")
            end
            TH() do
              I18n.t("crm.import.settings.table.status")
            end
            TH() do
              I18n.t("crm.import.settings.table.action")
            end
          end
        end

        def setting_scope
          hash_attributes = {schema_id: request.params[:schema_id], visible: true}
          scope = if @current_class
            Dynamic::Import::Setting.for_klass(@current_class)
          else
            Dynamic::Import::Setting
          end
          scope.where(hash_attributes).includes(setting_includes)
        end

        def setting_includes
          {
            include: {
              sources: {
                include: {
                  original_csv: csv_includes,
                }
              },
              jobs: {
                include: {
                  source: {
                    include: {
                      original_csv: csv_includes,
                    }
                  },
                }
              }
            }
          }
        end

        def toggle_sort(attribute, sort_variable)
          instance_variable_set(sort_variable, instance_variable_get(sort_variable) == 'asc' ? 'desc' : 'asc')
          @settings = settings.sort_by { |set| Time.parse(set.public_send(attribute)) }
          @settings.reverse! if instance_variable_get(sort_variable) == 'desc'
        end

        def cancel_filter
          @current_class = nil
          @created_at_sort = nil
          @import_date_sort = nil
        end

        def sort_icon_class(sort_variable)
          return 'fa-solid fa-sort mr-2' unless sort_variable
          sort_variable == 'asc' ? 'fa-solid fa-caret-up mr-2' : 'fa-solid fa-caret-down mr-2'
        end
      end
    end
  end
end
