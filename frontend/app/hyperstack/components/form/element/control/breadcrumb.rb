class Form
  module Element
    module Control
      class Breadcrumb < Base

        param :current, default: nil

        render { content }

        def render_input
          NAV(class: "form-breadcrumb") do
            form.pages.each do |i, page_data|
              classes = ["form-breadcrumb-step"]
              classes << "active" if current == i
              classes << "before-active" if current == i + 1
              BUTTON(class: classes) do
                if (page_data[:icon])
                  I(class: "fa-solid fa-#{page_data[:icon]}")
                end
                page_data[:label] || I18n.t("form/element/control/breadcrumb.page", number: i)
              end.on(:click) do |event|
                event.prevent_default
                form.go_to_page(i)
                mutate
              end
            end
          end
        end

        def render_readonly
          stub
        end

        def render_edit_in_place
          stub
        end
      end
    end
  end
end