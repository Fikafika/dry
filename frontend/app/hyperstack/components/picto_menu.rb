class PictoMenu < HyperComponent
  include Hyperstack::Router::Helpers

  param :menu, default: nil

  collect_other_params_as :others

  render do
    group = menu.in_groups(2, false)
    DIV(class: "container") do
      group.each do |arr|
        DIV(class: "row") do
          arr.each do |h|
            DIV(class: "col-6 align-middle text-center px-0") do
              DIV(class: "flex-row") do
                Link(h[:target], class: "btn w-100 btn-transparent-light-yiq shadow-none") do
                  DIV(class: "row justify-content-center") do
                    SPAN(class: "fa fa-#{h[:icon]} fa-3x pb-2") do
                    end
                  end
                  DIV(class: "row justify-content-center") do
                    SPAN(class:"text-center") do
                      "#{h[:text]}"
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

end
