require 'sidekiq/throttle_type'

ActiveSupport.on_load(:dynamic_export_worker) do
  include Dynamic::Notification::WorkerWithNotification
  include ::Sidekiq::ThrottleType::Job
  include Rails.application.routes.url_helpers

  module Dynamic
    module Export
      class Worker
        module WithNotification
          def perform(class_with_id, options = {})
            @progress = options['progress']

            @progress&.before_finish do |final_state|
              record_from_class_with_id(class_with_id) do |export_setting|
                @progress.data['record_id'] = export_setting.id
                @progress.data['record_type'] = export_setting.class.name
                if final_state == 'success'
                  @progress.data['result_export_download_path'] = rails_blob_path(export_setting.result_export.blob, disposition: "attachment", only_path: true)
                elsif final_state == 'fail'
                  @progress.data['export_errors'] = export_setting.export_errors
                end
              end
            end
            return if @progress&.canceled?

            @progress&.start
            super(class_with_id, options)
            if @progress
              record_from_class_with_id(class_with_id) do |export_setting|
                if export_setting.export_errors.present?
                  @progress.fail
                else
                  @progress.success
                end
              end
            end
          end
        end
      end
    end
  end
  prepend Dynamic::Export::Worker::WithNotification
end
