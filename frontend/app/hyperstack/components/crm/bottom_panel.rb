class Crm
  class BottomPanel < ::HyperComponent
    include Hyperstack::Router::Helpers

    param :id, default: "bottom-panel", type: String
    param :columns_render, default: 1, type: Integer


    render(DIV) do
      columns_width = 12 / columns_render

      DIV(id: id, class: "modal fade", role: 'dialog', 'data-backdrop': true) do
        DIV(class: "modal-dialog bottom-modal m-0 w-100 mw-100 shadow-sm", role: 'document') do
          DIV(class: 'modal-content border-0 rounded-0') do
            DIV(class: 'modal-body w-100 p-0 bg-light-yiq') do
              DIV(class: "container") do
                DIV(class: "row") do
                  children.each do |c|
                    DIV(class: "col-#{columns_width} align-middle text-center px-0") do
                      DIV(class: "flex-row") do
                        c.render
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

    end

    class Button < HyperComponent
      include Hyperstack::Router::Helpers

      param :target, default: nil
      param :icon
      param :text
      param :toggle, default: nil
      param :dismiss, default: nil

      collect_other_params_as :other_params

      render() do
        additional_params = {
          class_name: "btn w-100 btn-light-yiq shadow-none"
        }
        additional_params[:'data-toggle'] = toggle if toggle
        additional_params[:'data-dismiss'] = dismiss if dismiss
        additional_params[:'data-open-panel'] = other_params[:'data-open-panel'] if other_params.has_key?(:'data-open-panel')
        Link(target, other_params.merge(additional_params)) do
          DIV(class: "row justify-content-center") do
            H5(class: "fa fa-#{icon} fa-2x") do
            end
          end
          DIV(class: "row justify-content-center") do
            H6(class:"text-center") do
              "#{text}"
            end
          end
        end
      end

    end

  end
end
