class Crm
  class Import
    module Step
      class CheckImport < Base

        render { content }

        def content # TODO: Rework, once backend for TEST import. HIDE step 4 in the meanwhile ?
          DIV do
            DIV(class: "row p-2 my-3 justify-content-center") do
              step_progress
            end
            DIV(class: "row p-2 mt-5 font-italic") do
              I18n.t('crm.import.settings.test_import_msg')
            end
            DIV(class: "row mt-2") do
              DIV(class: "col-6") do
                DIV(class: "row") do
                  H4() do
                    I18n.t('crm.import.settings.test_import_lines')
                  end
                end
                DIV(class: "row") do
                  INPUT(type:"text", class: "flex-fill", name:"", value: @test_lines || 10) do
                  end.on(:change) do |evt|
                    mutate @test_lines = evt.target.value
                  end
                end
                DIV(class: "row mt-2 float-right") do
                  BUTTON(class:"btn btn-primary border-0 rounded-0 mx-2", type:"button") do
                    I18n.t('crm.import.settings.import')
                  end.on(:click) do |event|
                    event.prevent_default
                    # TODO
                  end
                end
                DIV(class: "row mt-5") do
                  P() do
                    #"TEST IMPORT STATUS here...once backend"
                  end
                end
              end # left col
              DIV(class: "col-6") do
                DIV(class: "row ml-2") do
                  P() do
                    #"TEST LOGS here...once backend"
                  end
                end
              end # right col
            end

            footer
          end
        end
      end

    end # end of setting
  end
end
