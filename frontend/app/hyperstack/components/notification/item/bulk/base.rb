module Notification
  module Item
    module Bulk
      class Base < ::Notification::Item::Base # abstract
        include Hyperstack::Router::Helpers
        include ::Router::Resources
        include ::Crm::Routes::Helpers

        render { content }

        def icon
          'pencil-alt'
        end

        def title
          I18n.t(
            title_i18n_key,
            count: record.total.to_i,
            klass_name: (klass ? klass.model_name.human(count: record.total.to_i).downcase : ''),
            form_name: (form ? form : ''),
            gender: klass&.model_name.try(:gender), # TODO implement gender in translations
          )
        end

        def title_i18n_key
          raise 'not implemented'
        end

        def klass
          @klass ||= record.data&.dig('klass_name')&.safe_constantize
        end

        def form
          @form ||= record.data&.dig('form_name')
        end

        def actions_for_succeeded
          reload_btn
        end

        def actions_for_failed
          reload_btn
        end

        def explaination
          return unless success_count || error_count
          SPAN(class: 'pl-2 pr-2') do
            counts = [
              success_count ? I18n.t('notifications.success_count', count: success_count) : nil,
              error_count ? I18n.t('notifications.error_count', count: error_count) : nil,
            ].compact.join(', ')
            "(#{counts})"
          end
        end

        def error_count
          record.data[:error_count]
        end

        def success_count
          record.data[:success_count]
        end

        def reload_btn
          DIV(class: 'd-flex flex-row ml-auto') do
            A(href: '#reload_grid', class: 'btn btn-light-yiq') do
              I(class: 'fa fa-redo fa-fw'){}
              I18n.t('shared.refresh')
            end.on(:click) do |event|
              event.prevent_default
              ::Element['.crm-index'].trigger(:reload)
            end
          end
        end
      end
    end
  end
end
