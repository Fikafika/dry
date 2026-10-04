ActiveSupport.on_load(:dynamic_copy_worker) do
  include Dynamic::Notification::WorkerWithNotification

  module Dynamic
    module Copy
      class Worker
        module WithNotification
          def perform(class_with_id, options = {})
            @progress = options['progress']

            @progress&.before_finish do |final_state|
              record_from_class_with_id(class_with_id) do |setting|
                @progress.data['record_id'] = setting.id
                @progress.data['record_type'] = setting.class.name
                if final_state == 'success'
                  @progress.data['result_record_ids'] = setting.result_record_ids
                  @progress.data['result_record_type'] = setting.mapping.target_klass_name
                elsif final_state == 'fail'
                  @progress.data['run_errors'] = setting.run_errors
                end
              end
            end
            return if @progress&.canceled?

            @progress&.start
            super(class_with_id, options)
            if @progress
              record_from_class_with_id(class_with_id) do |setting|
                if setting.run_errors.present?
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
  prepend Dynamic::Copy::Worker::WithNotification

end
