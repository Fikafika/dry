class Crm
  class Import
    class StepProgress < HyperComponent

      param :current_step, default: 1, type: Integer
      param :is_new_setting, default: false, type: Boolean

      fires :go_to_step

      TRANSLATION_KEY_BY_STEP_NUMBER = {
        1 => 'first',
        2 => 'second',
        3 => 'third',
        4 => 'fourth',
        5 => 'fifth',
        6 => 'sixth',
      }.freeze

      render { content }

      def content
        DIV(class: 'd-flex flex-row pt-3 w-100 bg-white fixed-top justify-content-center step-progress-mapping', style: {top: '3.375rem', zIndex: 0}) do
          TRANSLATION_KEY_BY_STEP_NUMBER.each do |k, v|
            if k > 1
              DIV(class:"fa fa-chevron-right m-2 align-self-center text-#{style_category(k)}") do
              end
            end
            BUTTON(class: "btn rounded-0 border-0 m-0 p-2 btn-#{style_category(k)}", disabled: is_disabled?(k)) do
              I18n.t("crm.import.settings.step.#{v}")
            end.on(:click) do |event|
              event.prevent_default
              go_to_step!(k)
            end
          end
        end
      end

      def is_disabled?(index)
        index == 1 ? false : is_new_setting
      end

      def style_category(k)
        k <= current_step ? 'primary' : 'secondary'
      end

    end

  end
end
