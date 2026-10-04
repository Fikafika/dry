# backtick_javascript: true

class Crm
  class Import
    module Step
      class Encoding < Base

        render do
          if setting.loaded?
            content
          end
        end

        def content
          DIV(class: "d-flex flex-lg-row flex-column-reverse pt-3 mt-5") do
            DIV(class: "col p-0") do
              H4(class: 'mt-3') do
                I18n.t('crm.import.settings.advanced_params.separator')
              end
              DIV(class: 'form-group') do
                LABEL do
                  I18n.t('crm.import.settings.advanced_params.col_delimiter')
                end
                INPUT(type: 'text', class: 'flex-fill form-control w-auto', name: '', value: source.column_delimiter || ';') do
                end.on(:change) do |evt|
                  mutate source.attributes[:column_delimiter] = evt.target.value
                end
              end
              DIV(class: 'form-group') do
                LABEL do
                  I18n.t("crm.import.settings.advanced_params.row_delimiter")
                end
                INPUT(type: 'text', class: "flex-fill form-control w-auto", name: '', value: source.line_delimiter) do
                end.on(:change) do |evt|
                  mutate source.attributes[:line_delimiter] = evt.target.value
                end
              end
              DIV(class: 'form-group') do
                LABEL do
                  I18n.t('crm.import.settings.advanced_params.quotation_mark')
                end
                INPUT(type: 'text', class: 'flex-fill form-control w-auto', name: '', value: source.quote_char || '"') do
                end.on(:change) do |evt|
                  mutate source.attributes[:quote_char] = evt.target.value
                end
              end
              DIV(class: 'form-check') do
                @check1 = source.has_title_line.nil? ? true : source.has_title_line
                INPUT(type: 'checkbox', class: 'form-check-input', checked: @check1) do
                end.on(:change) do |evt|
                  mutate source.attributes[:has_title_line] = !@check1
                end
                LABEL(class: 'form-check-label') do
                  I18n.t('crm.import.settings.advanced_params.has_header')
                end
              end

              H4(class: 'mt-3') do
                SPAN() do
                  I18n.t('crm.import.settings.advanced_params.encoding')
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
                  generate_dropdown_subclasses(Dynamic::Import::Transformation::Base.subclasses_by_type[:encoding])
                end
              end
            end
            DIV(class: "col-12 col-lg-4 p-0") do
              src = "" # TODO create import settings tutorial video
              if src.present?
                DIV(class: "embed-responsive embed-responsive-16by9 border border-primary") do
                  IFRAME(class: "embed-responsive-item", src: src) do
                  end
                end
              end
            end
          end
          footer
          if !source.new_record? && source.loaded?
            DIV(class: "d-flex flex-column mt-3") do
              H4() do
                I18n.t("crm.import.settings.preview")
              end
              if source.first_lines.empty?
                I18n.t("crm.import.sources.no_preview")
              else
                Crm::Import::CsvPreview(source: source)
              end
            end
          else
            I18n.t("crm.import.sources.no_preview")
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
            next unless Dynamic::Import::Transformation::Base.subclasses_by_type[:encoding].include?(t.class)
            type = t.type.demodulize
            item = Item.from_type(type).build_item(t, output)
            @items.push(item)
          end
        end
      end
    end
  end
end
