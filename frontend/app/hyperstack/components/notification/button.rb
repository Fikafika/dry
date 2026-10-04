module Notification

  class Button < HyperComponent
    include Hyperstack::Router::Helpers

    param :action
    param :icon
    param :variant, default: 'light'
    param :record

    fires :click

    render do
      observe record
      Link("##{action}", class: "btn btn-#{variant} #{@disabled ? 'disabled' : ''}", title: I18n.t("shared.#{action}")) do
        I(class: "fa fa-#{icon}"){}
      end.on(:click) do |e|
        e.prevent_default
        unless @disabled
          @disabled = true
          mutate
          record.send(action).always do
            @disabled = false
            record.mutate # why record is not always mutated ?
            mutate
          end
        end
      end
    end
  end

end

