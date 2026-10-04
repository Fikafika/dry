module Dynamic
  class Notification
    module WorkerWithNotification; extend ActiveSupport::Concern

      class_methods do
        def create_notification(job)
          return unless User.current&.id

          class_with_ids = job['args']&.first
          class_with_ids = [class_with_ids] if class_with_ids.is_a?(String)
          klass = nil
          klass_name = nil
          if class_with_ids.is_a?(Array) && class_with_ids.first
            klass_name = class_with_ids.first.split('-').first
            klass = klass_name.safe_constantize
          end
          schema_name = klass_name.split('::')[1]
          unless klass
            Dynamic::Schema.load(schema_name)
            klass = klass_name.safe_constantize
          end
          unless klass
            raise "unknown klass #{klass_name.inspect}"
          end
          notification_klass = "D::#{schema_name}::R::Notification".safe_constantize
          notification_klass_name = self.module_parent.name.demodulize
          klasses = class_with_ids&.map do |r|
            r&.split('-')&.first&.safe_constantize
          end.compact.uniq.map do |r|
            r.model_name.human(count: 2).downcase # TODO implement count
          end.join(', ')

          title = I18n.t("notification.titles.#{notification_klass_name.underscore}", klasses: klasses, default: notification_klass_name)
          icon = I18n.t("notification.icons.#{notification_klass_name.underscore}", default: 'gear')

          self.load_schema_if_missing_model(schema_name) do
            notification_klass&.create!(
              state: :pending,
              user_id: User.current.id,
              klass_name: notification_klass_name,
              title: title,
              icon: icon,
              can_cancel: true
            )
          end
        end

      private

        def load_schema_if_missing_model(schema_name)
          tries ||= 0
          begin
            yield if block_given?
          rescue NameError => e
            if e.message =~ /Missing model/ && tries == 0
              Rails.logger.info "retry load schema #{schema_name} after #{e.message}"
              tries += 1
              Dynamic::Schema.load(schema_name) do
                yield if block_given?
              end
            else
              raise
            end
          end
        end

      end

    end
  end
end