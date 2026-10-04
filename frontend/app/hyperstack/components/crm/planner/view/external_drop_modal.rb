class Crm
  class Planner
    class View
      class ExternalDropModal < ::Modal

        render { content }

        param :type

        fires :confirm_add_has_many

        def body
          DIV do
            body_message
          end
        end

        def body_message
          type == 'HasMany' ? I18n.t('crm.planner.modal.drop_hasMany_replace_text') : I18n.t('crm.planner.modal.drop_replace_text')
        end

        def title
          I18n.t('crm.planner.modal.drop_confirmation')
        end

        def footer
          case type
          when :enum, :BelongsTo
            regular_footer
          when :HasMany
            has_many_footer
          end
        end

        def regular_footer
          BUTTON(class:'btn bg-light mr-2', type:'button') do
            I18n.t('shared._no')
          end.on(:click) do |event|
            cancel
          end
          BUTTON(class:'btn btn-primary', type:'button') do
            I18n.t('shared._yes')
          end.on(:click) do |event|
            confirm
          end
        end

        def has_many_footer
          BUTTON(class:'btn bg-light mr-2', type:'button') do
            I18n.t('shared.cancel')
          end.on(:click) do |event|
            cancel
          end
          BUTTON(class:'btn btn-secondary', type:'button') do
            I18n.t('crm.planner.modal.add_btn_text')
          end.on(:click) do |event|
            confirm_add_has_many!
            close
          end
          BUTTON(class:'btn btn-primary', type:'button') do
            I18n.t('crm.planner.modal.replace_btn_text')
          end.on(:click) do |event|
            confirm
          end
        end
      end
    end
  end
end
