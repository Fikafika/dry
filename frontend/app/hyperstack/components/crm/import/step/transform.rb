class Crm
  class Import
    module Step
      class Transform < Base

        render do
          content if setting.loaded?
        end

        def content
          DIV do
            DIV(class: 'd-flex flex-column mt-5 pt-5') do
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
                      A(href: source.original_csv.download_path) do
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
              H4(class: 'mt-3') do
                SPAN() do
                  I18n.t('crm.import.settings.transformation.title')
                end
                I(class: 'fa fa-fw fa-xs fa-question-circle ml-2', title: I18n.t('crm.import.settings.transformation.msg_1'))
              end
              return unless source.setting_id
              if source.try(:csv)&.attached?
                transformations_to_items
                if @items
                  DIV(class: 'list-group') do
                    @items.each_with_index do |item, i|
                      if !item.key?('_destroy')
                        Crm::Import::Step::Item.from_type(item['type']).insert_element(transformation: item, item_index: i, output: output, source: source)
                        .on(:remove) do |item_index|
                          if @items[item_index].key?('id')
                            @items[item_index] = { id: @items[item_index]['id'], _destroy:1, type: @items[item_index]['type'] }
                          else
                            @items.delete_at(item_index)
                          end
                          mutate
                        end
                      end
                    end
                  end
                end
                DIV(class: 'dropdown mt-1') do
                  BUTTON(class: "btn btn-light dropdown-toggle", type: "button", 'data-toggle': 'dropdown' ) do
                    I18n.t('shared.add')
                  end
                  generate_dropdown_subclasses(Dynamic::Import::Transformation::Base.subclasses_by_type[:transform])
                end
              end
              footer
              if !output.new_record? && output.loaded?
                preview_for_transformed_csv
              else
                I18n.t('crm.import.sources.no_preview')
              end
            end
          end
        end

        def setting_includes
          {
            include: {
              transformations: 1,
              output: {
                include: {
                  title_line: 1,
                  first_lines: 1,
                  csv: csv_includes,
                  original_csv: csv_includes
                }
              },
              sources: {
                include: {
                  title_line: 1,
                  first_lines: 1,
                  transformations: 1,
                  transformation: 1,
                  csv: csv_includes,
                  original_csv: csv_includes,
                }
              },
            }
          }
        end

        def output
          setting.output
        end

        def transformations_to_items
          return if @items
          @items = []
          setting_transformations = setting.transformations.select { |t| t.class != Dynamic::Import::Transformation::Base }.sort_by(&:position)
          setting_transformations.each do |t|
            next unless Dynamic::Import::Transformation::Base.subclasses_by_type[:transform].include?(t.class)
            type = t.type.demodulize
            item = Item.from_type(type).build_item(t, output)
            @items.push(item)
          end
        end

        def items_to_transformations
          return @items_to_transformations if @items_to_transformations
          @items_to_transformations = []
          parent_id = nil
          input = source
          @items.each_with_index do |item, index|
            type = item['type'].to_s.demodulize
            transformation = Item.from_type(type).build_transformation(item, parent_id, input, index)
            @items_to_transformations.push(transformation)
            if Item.from_type(type).has_parent_id?
              input = nil
              parent_id = transformation['id']
            else
              input = source
              parent_id = nil
            end
          end
          return @items_to_transformations
        end

        def process_cancel_button
          setting.reload do |response|
            @items = nil
            mutate setting
          end
        end

        def process_action_on_success
          @items = nil
        end

        def object_to_save
          setting.update(transformations_attributes: items_to_transformations)
        end

        def process_save_button(event)
          if source.try(:csv)&.attached? && items_to_transformations
            super(event)
          end
        end

        def preview_for_transformed_csv
          DIV(class: 'd-flex flex-row mt-3 mb-2') do
            H4() do
              I18n.t('crm.import.settings.preview')
            end
            if output.try(:csv)&.attached?
              A(href: output.csv.download_path, class: 'btn btn-light ml-1', type: 'button') do
                I(class: 'd-flex fa fa-download align-items-center')
              end
            end
          end
          if output.first_lines.nil? || output.first_lines.empty?
            I18n.t('crm.import.sources.no_preview')
          else
            Crm::Import::CsvPreview(source: output)
          end
        end
      end

      module Item

        class Base < HyperComponent

          param :output
          param :source
          param :transformation
          param :item_index

          collect_other_params_as :other_params

          fires :remove

          render { content }

          def content
            DIV(class: 'list-group-item flex-column p-0') do
              DIV(class: 'd-flex flex-row p-2') do
                H5(class: 'text-left flex-grow-1 mb-0') do
                  transformation['type'].safe_constantize.model_name.human
                end
                remove_button
              end
              body
            end
          end

          def body
          end

          def self.has_parent_id?
            false
          end

          def self.should_be_first?
            false
          end

          def remove_button
            DIV(class: 'btn-group') do
              A(href: '#', class: 'd-flex flex-row btn btn-light', type:'button') do
                I(class: 'd-flex fa fa-trash align-items-center')
              end.on(:click) do |event|
                event.prevent_default
                remove!(item_index)
              end
            end
          end

          def self.build_transformation(transformation, parent_id, input, index)
            id = transformation.key?('id')? transformation['id'] : HyperResource::Base.generate_uuid
            item = { id: id, type: transformation['type'], apply_on_create: true, position: index }
            if input
              item['input_id'] = input.id
            end
            return item
          end

          def self.build_item(transformation, source)
            return { id: transformation.id, type: transformation.type }
          end
        end

        class SplitCell < Base

          render { content }

          def body
            TABLE(class: 'w-100') do
              TBODY() do
                transformation['columns'].each_with_index do |item, j|
                  type = transformation['type'].to_s.split('::').last
                  "Crm::Import::Step::Item::#{type}::SubItem".safe_constantize.insert_element(output: output, item: item, item_index: j, transformation: transformation)
                  .on(:remove) do |index|
                    transformation['columns'].delete_at(index)
                    if transformation['columns'].empty?
                      remove!(item_index)
                    end
                    mutate
                  end
                end
              end
            end
            DIV(class: 'd-flex flex-row p-2') do
              A(class: 'btn btn-light', type: 'button') do
                I(class: 'd-flex fa fa-plus align-items-center')
              end.on(:click) do
                transformation['columns'].push({'column' => 'A', 'row_delimiters' => ''})
                mutate
              end
            end
          end

          def self.has_parent_id?
            true
          end

          def self.build_transformation(transformation, parent_id, input, index)
            if transformation.key?('_destroy')
              return transformation
            end
            columns = []
            delimiters = []
            transformation['columns'].each do |item|
              columns.push(item['column'])
              delimiters.push(item['row_delimiters'])
            end
            return super.merge(columns: columns, parent_id: parent_id, row_delimiters: delimiters, set_output_attributes: true)
          end

          def self.build_item(transformation, source)
            columns = []
            if transformation.columns.is_a?(Array)
              row_delimiters = transformation.row_delimiters || []
              transformation.columns.each_with_index do |t, i|
                item = { column: t, row_delimiters: row_delimiters[i] }
                columns.push(item)
              end
            else
              if transformation.row_delimiters.any?
                transformation.row_delimiters.each do |rd|
                  columns.push({ column: [], row_delimiters: rd })
                end
              else
                columns.push({ column: [], row_delimiters: [] })
              end
            end
            return super.merge(columns: columns)
          end

          class SubItem < HyperComponent

            param :output
            param :item
            param :item_index

            collect_other_params_as :other_params

            fires :remove

            render { content }

            def content
              TR() do
                TD(class: 'p-2 col-5') do
                  SELECT(class: 'custom-select bg-light-yiq border-0', style: {cursor: 'pointer'}, value: item['column']) do
                    output.title_line.each_with_index do |title, k|
                      OPTION(value: (k+1).to_s26.upcase) do
                        title
                      end
                    end
                  end.on(:change) do |evt|
                    mutate item['column'] = evt.target.value
                  end
                end
                TD(class: 'p-2 col-5') do
                  INPUT(type: 'text', class: 'flex-fill w-100 form-control', placeholder: I18n.t('crm.import.settings.transformation.cell_delimiter'), value: item['row_delimiters'] || '') do
                  end.on(:change) do |evt|
                    mutate item['row_delimiters'] = evt.target.value
                  end
                end
                TD(class: 'p-2 text-right col-2') do
                  A(href: '#remove', class: 'btn btn-light', type: 'button') do
                    I(class: 'd-flex fa fa-minus align-items-center')
                  end.on(:click) do |event|
                    event.prevent_default
                    remove!(item_index)
                  end
                end
              end
            end
          end

        end

        class CreateColumn < Base

          render { content }

          def body
            TABLE(class: 'w-100') do
              TBODY() do
                item = transformation['columns'][0]
                TR() do
                  TD(class: 'p-2 col-5') do
                    INPUT(type: 'text', class: 'flex-fill w-100 form-control', placeholder: I18n.t('crm.import.settings.table.column_title'), value: item['new_col_name'] || '') do
                    end.on(:change) do |evt|
                      mutate item['new_col_name'] = evt.target.value
                    end
                  end
                  TD(class: 'p-2 col-5') do
                    TEXTAREA(class: 'flex-fill w-100 form-control', placeholder: I18n.t('activerecord.defaults.attributes.formula'), value: item['formula'] || '') do
                    end.on(:change) do |evt|
                      mutate item['formula'] = evt.target.value
                    end
                  end
                  TD(class: 'p-2 text-right col-2') do
                  end
                end
              end
            end
          end

          def self.has_parent_id?
            true
          end

          def self.build_transformation(transformation, parent_id, source, index)
            if transformation.key?('_destroy')
              return transformation
            end
            return super.merge(parent_id: parent_id, new_col_name: transformation['columns'][0]['new_col_name'], formula: transformation['columns'][0]['formula'], set_output_attributes: true )
          end

          def self.build_item(transformation, source)
            return super.merge(columns: [{ new_col_name: transformation.new_col_name, formula: transformation.formula }])
          end

          def lsp_url
            href = App.location.href
            domain = href.split('/')[2]
            ws_protocol = href.start_with?('https') ? 'wss' : 'ws'
            return "#{ws_protocol}://#{domain}#{ENV['APP_PATH_PREFIX']}/api/lsp"
          end
        end

        class Encoder < Base

          render {content}

          def self.should_be_first?
            true
          end

          def self.build_transformation(transformation, parent_id, source, index)
            if transformation.key?('_destroy')
              return transformation
            end
            return super.merge(output_id: source.id, parent_id: parent_id, input_encoding: transformation['input_encoding'])
          end

          def body
            DIV(class: 'd-flex flex-row') do
              item = transformation
              DIV(class: 'dropdown p-2') do
                BUTTON(class: "btn btn-light rounded-0 border-0 dropdown-toggle", type: "button", 'data-toggle': 'dropdown') do
                  A() do
                    item['input_encoding']
                  end
                end
                DIV(class: 'dropdown-menu dropdown-menu-right') do
                  encoding_list.each do |title|
                    A(class: 'dropdown-item', href: '#') do
                      title
                    end.on(:click) do |evt|
                      mutate item['input_encoding'] = title
                    end
                  end
                end
              end
              I(class: 'fa fa-arrow-right align-self-center px-2')
              DIV(class: 'dropdown p-2') do
                BUTTON(class: "btn btn-light rounded-0 border-0 disabled dropdown-toggle", type: "button", 'data-toggle': 'dropdown') do
                  A() do
                    "UTF-8"
                  end
                end
              end
            end
          end

          def encoding_list
            return [
              "WINDOWS-1252",
              "UTF-8",
              "ISO-8859-1",
              "MACINTOSH"
            ]
          end

          def self.build_item(transformation, source)
            return super.merge(input_encoding: transformation.input_encoding)
          end

        end

        class WindowsToUnixEndOfLine < Base

          render {content}

          def self.build_transformation(transformation, parent_id, source, index)
            if transformation.key?('_destroy')
              return transformation
            end
            return super.merge(output_id: source.id)
          end

          def body
            DIV(class: 'd-flex flex-row p-2') do
              INPUT(type: 'text', class:'form-control w-auto', value: "\\n\\r", disabled: true) do
              end
              I(class: 'fa fa-arrow-right align-self-center px-2')
              INPUT(type: 'text', class:'form-control w-auto', value: "\\n", disabled: true) do
              end
            end
          end

        end

        class MacToUnixEndOfLine < Base

          render {content}

          def self.build_transformation(transformation, parent_id, source, index)
            if transformation.key?('_destroy')
              return transformation
            end
            return super.merge(output_id: source.id)
          end

          def body
            DIV(class: 'd-flex flex-row p-2') do
              INPUT(type: 'text', class:'form-control w-auto', value: "\\r", disabled: true) do
              end
              I(class: 'fa fa-arrow-right align-self-center px-2')
              INPUT(type: 'text', class:'form-control w-auto', value: "\\n", disabled: true) do
              end
            end
          end
        end

        class EscapeQuote < Base

          render {content}

          def self.build_transformation(transformation, parent_id, source, index)
            if transformation.key?('_destroy')
              return transformation
            end
            return super.merge(output_id: source.id)
          end

          def body
            DIV(class: 'd-flex flex-row p-2') do
              INPUT(type: 'text', class:'form-control w-auto', value: '"', disabled: true) do
              end
              I(class: 'fa fa-arrow-right align-self-center px-2')
              INPUT(type: 'text', class:'form-control w-auto', value: '""', disabled: true) do
              end
            end
          end
        end

        def self.from_type(type)
          "Crm::Import::Step::Item::#{type.demodulize}".safe_constantize || Base
        end

      end
    end
  end
end
