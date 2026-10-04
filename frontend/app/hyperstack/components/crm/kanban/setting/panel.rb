require 'components/crm'

class Crm
  class Kanban
    module Setting
      class Panel < HyperComponent
        param :schema
        param :klass
        param :mode, default: nil

        collect_other_params_as :other_params

        fires :save_setting

        render do
          DIV(class: 'mt-4') do
            Crm::Kanban::Setting::Form({schema: schema, klass: klass, mode: mode}.merge(other_params)) do
              DIV(class: 'd-flex justify-content-end mt-2') do
                BUTTON(class: 'btn btn-primary', type: 'submit') { I18n.t('shared.save') }
              end
            end.on(:save) do
              save_setting!
            end
          end
        end
      end
    end
  end
end
