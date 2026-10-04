class Crm
  class Import
    class CsvPreview < HyperComponent

      param :source


      render() do
        DIV(class: "overflow-auto") do
          DIV(class:"table-responsive") do
            TABLE(class:"table table-striped") do
              THEAD() do
                TR(class:"text-left bg-light") do
                  TH()
                  if source.has_title_line
                    source.title_line.each_with_index do |header, i|
                      TH('data-toggle': 'tooltip', title: header) do
                        "#{(i + 1).to_s26.upcase} - #{header&.truncate(20)}"
                      end
                    end
                  else
                    source.title_line.each_with_index do |v, i|
                      TH() do
                        "#{(i + 1).to_s26.upcase} - #{I18n.t("crm.import.settings.table.column")}"
                      end
                    end
                  end
                end
              end # end of thead
              TBODY() do
                source.first_lines.each do |line|
                  TR() do
                    TD() do
                    end
                    line.each do |cell|
                      TD() do
                        cell&.truncate(30)
                      end
                    end
                  end
                end
              end #end of tbody
            end #end of table
          end
        end
      end

    end
  end
end
