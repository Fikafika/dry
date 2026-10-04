class Crm
  class Sheet

    class CloseButton < ::Crm::Base

      param :side
      collect_other_params_as :other_params

      render do
        Icon(
          text: I18n.t('shared.close'),
          icon: "chevron-#{side || 'left'}",
          icon_position: side == 'left' ? 'right' : 'left',
          variant: 'transparent-light-yiq',
        ).on(:click) do |event|
          event.prevent_default
          event.stop_propagation
          App.history.push(App.location.remove_param(panel_param(side)))
        end
      end

      class Icon < HyperComponent
        include Hyperstack::Router::Helpers

        param :icon, default: ''#, type: String
        param :text, default: '', type: String
        param :target, default: ''#, type: String
        param :variant, default: 'light', type: String
        param :shape, default: 'border-0 rounded-0', type: String
        param :text_break, default: 'text-break', type: String
        param :icon_position, default: 'left', type: String

        collect_other_params_as :other_params

        fires :click

        render() do
          css_class = "ib btn btn-#{variant} #{shape} #{text_break} #{other_params[:className]}"
          link_params = {class_name: css_class}
          other_params&.each{|k, v| link_params[k] = v if k.start_with?('data-')}

          Link(target, link_params) do
            DIV(class: 'd-flex flex-row justify-content-start align-items-center') do
              if icon_position == 'right'
                text_
                icon_
              else
                icon_
                text_
              end
            end
          end.on(:click) do |event|
            click!(event)
          end
        end

        def icon_
          I(class: "ib-icon ib-icon-left #{icon_position == 'left' ? 'pr-2' : 'pl-2'} fa fa-#{icon} fa-fw")
        end

        def text_
          SPAN(class: "ib-text") do
            text
          end
        end
      end

    end

  end
end
