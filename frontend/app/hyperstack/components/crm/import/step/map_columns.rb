class Crm
  class Import
    module Step
      class MapColumns < Base
        include ::PermittedKlass

        render do
          content if setting.loaded?
        end

        after_update do
          ::Element.find('[data-toggle="tooltip"]').tooltip()
        end

        def content
          DIV(class: 'd-flex flex-column pt-5 mt-5') do
            DIV(class: 'd-flex flex-row') do
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
                    A(href: file.download_path) do
                      I(class:'fa fa-download')
                      SPAN(class: 'ml-1') do
                        file&.filename
                      end
                    end
                  else
                    I18n.t('crm.import.settings.no_file')
                  end
                end
              end
            end
            DIV(class: 'form-check mt-3') do
              @check2 = source.add_possible_values.nil? ? false : source.add_possible_values
              INPUT(type: 'checkbox', class: 'form-check-input', checked: @check2) do
              end.on(:change) do |evt|
                mutate source.add_possible_values = !@check2
              end
              LABEL(class: 'form-check-label') do
                I18n.t("crm.import.settings.advanced_params.add_possible_values")
              end
            end

            DIV(class: 'form-check') do
              @check3 = source.accumulate_values.nil? ? true : source.accumulate_values
              INPUT(type: 'checkbox', class: 'form-check-input', checked: @check3) do
              end.on(:change) do |evt|
                mutate source.accumulate_values = !@check3
              end
              LABEL(class: 'form-check-label') do
                I18n.t("crm.import.settings.advanced_params.accumulate_values")
              end
            end
            DIV(class: 'form-check mb-1') do
              @check4 = source.allow_remove.nil? ? false : source.allow_remove
              INPUT(type: 'checkbox', class: 'form-check-input', checked: @check4) do
              end.on(:change) do |evt|
                mutate source.allow_remove = !@check4
              end
              LABEL(class: 'form-check-label') do
                I18n.t('crm.import.settings.edit_columns.empty_cells')
              end
            end
            DIV(class: 'form-check') do
              INPUT(type: 'checkbox', class: 'form-check-input') do
              end.on(:change) do |evt|
              end
              LABEL(class: 'form-check-label') do
                I18n.t('crm.import.settings.advanced_params.delete_import')
              end
            end
            H4(class: 'mt-3') do
              SPAN() do
                I18n.t('crm.import.settings.edit_columns.title')
              end
              I(class: 'fa fa-fw fa-xs fa-question-circle ml-2', 'data-toggle': 'tooltip', title: I18n.t('crm.import.settings.edit_columns.title_info'))
            end
            DIV(class: 'form-group mb-2') do
              LABEL do
                I18n.t("crm.import.sources.type") + " :"
              end
              DIV(class: 'ml-1 d-inline dropdown') do
                A(href:"#", class: "btn btn-light dropdown-toggle",  'data-toggle': 'dropdown') do
                  klass&.model_name&.human(count: 2) || I18n.t("shared.select")
                end
                DIV(class: 'border rounded-0 shadow dropdown-menu container p-0', style: {maxHeight: '50vh', overflow: 'auto'}) do
                  klasses.each do |k|
                    A(href: '#', class: 'dropdown-item', value: k.model_name.human(count: 2)) do
                      k.model_name.human(count: 2)
                    end.on(:click) do |evt|
                      evt.prevent_default
                      if klass&.name != k.to_s
                        reset_columns
                        @klass = k
                        source.klass_name = k.to_s
                        mutate
                      end
                    end
                  end
                end
              end
            end
            if klass && source.try(:csv)&.attached?
              mapping_table
            end
          end
          scroll_to_top_button
          footer
        end

        def reset_columns
          source.columns.each do |col|
            col.path = []
            col.when_create = true
            col.when_update = true
            # col.when_delete = false
          end
        end

        def mapping_table
          TABLE(class:'table mb-0 table-borderless') do
            THEAD() do
              TR(class: 'text-left') do
                TH do
                  # empty header
                end
                TH do
                  I18n.t('crm.import.settings.table.column_title')
                end
                TH do
                  I18n.t('crm.import.settings.table.values')
                end
                TH do
                  I18n.t('crm.import.settings.table.fields')
                end
                TH(class: 'text-center text-nowrap') do
                  SPAN do
                    I18n.t('crm.import.settings.table.when_create')
                  end
                  I(class: 'fa fa-fw fa-xs fa-question-circle', 'data-toggle': 'tooltip', title: I18n.t('crm.import.settings.table.when_create_info'))
                end
                TH(class: 'text-center text-nowrap')  do
                  SPAN do
                    I18n.t('crm.import.settings.table.when_update')
                  end
                  I(class: 'fa fa-fw fa-xs fa-question-circle', 'data-toggle': 'tooltip', title: I18n.t('crm.import.settings.table.when_update_info'))
                end
                # TH(class: 'text-center text-nowrap')  do
                #   SPAN do
                #     I18n.t('crm.import.settings.table.when_delete')
                #   end
                #   I(class: 'fa fa-fw fa-xs fa-question-circle', 'data-toggle': 'tooltip', title: I18n.t('crm.import.settings.table.when_delete_info'))
                # end
              end
            end
            TBODY() do
              if source.loaded?
                collection = source.title_line.empty? ? source.first_lines.first : source.title_line
                collection&.each_with_index do |head, i|
                  column = source.columns.detect{|col| col.position == i}
                  if !column
                    source.columns.new(position: i)
                  end
                end
                @columns_preview = columns_preview
                source.columns.sort_by{ |k| k.position }.each_with_index do |col, i|
                  TR(class: 'text-left') do
                    TD do
                      (i+1).to_s26.upcase
                    end
                    TD do
                      source.has_title_line ? source.title_line[i] : ""
                    end
                    TD do
                      if @columns_preview[i]
                        Crm::Import::ValuesPreviewCollapse(menu: @columns_preview[i], i: i)
                      end
                    end
                    TD(style: {display: 'flex'}) do
                      Crm::Import::AttributesDropdown(klass: klass, path: col.path).on(:change) do |path, previous_path|
                        col.path = path
                        if path[0].nil? && path[1].nil?
                          col._destroy = true
                        else
                          col.attributes.delete(:_destroy)
                        end
                        mutate
                      end
                    end
                    TD(class: 'text-center') do
                      Crm::Import::ColumnCheckbox(column: col, col_key: "when_create", default_value: true)
                    end
                    TD(class: 'text-center') do
                      Crm::Import::ColumnCheckbox(column: col, col_key: "when_update", default_value: true)
                    end
                    # TD(class: 'text-center') do
                    #   Crm::Import::ColumnCheckbox(column: col, col_key: "when_delete", default_value: false)
                    # end
                  end
                end
              end
            end
          end
        end

        def setting_includes
          {
            include: {
              output: {
                include: {
                  columns: 1,
                  title_line: 1,
                  first_lines: 1,
                  csv: csv_includes,
                  original_csv: csv_includes,
                }
              }
            },
          }
        end

        def object_to_save
          source.save
        end

        def klass
          @klass ||= source.klass_name&.safe_constantize
        end

        def klasses
          return @klasses if @klasses
          klass_names = schema.klasses.sort_by(&:human_name).map(&:const_absolute_name)
          permitted_klasses = permitted_klasses_for_action(klass_names, :C)
          @klasses = permitted_klasses.map(&:safe_constantize) if permitted_klasses.any?
          return @klasses || []
        end

        def file
          @file ||= source.original_csv
        end

        def source
          setting.output
        end

        def columns_preview
          first_lines = source.first_lines # need dup ?
          expected_column_count = first_lines.map(&:length).max
          first_lines.each do |l|
            if l.length < expected_column_count
              (expected_column_count - l.length).times do
                l << nil
              end
            end
          end
          return first_lines.transpose
        end

      end
    end
  end
end
