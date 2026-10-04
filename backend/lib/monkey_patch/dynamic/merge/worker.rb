require 'sidekiq/throttle_type'

ActiveSupport.on_load(:dynamic_merge_worker) do
  include Dynamic::Notification::WorkerWithNotification
  include ::Sidekiq::ThrottleType::Job

  module Dynamic
    module Merge
      class Worker
        module WithNotification
          def perform(class_with_id, options = {})
            @progress = options['progress']

            @progress&.before_finish do |final_state|
              record_from_class_with_id(class_with_id) do |setting|
                @progress.data['record_id'] = setting.id
                @progress.data['record_type'] = setting.class.name
                if final_state == 'success'
                  @progress.data['result_record_id'] = setting.result_record_id
                  @progress.data['result_record_type'] = setting.result_record_type
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
  prepend Dynamic::Merge::Worker::WithNotification

  module Dynamic
    module Merge
      class Worker
        module Versioning

          def perform(class_with_id, options = {})
            set_paper_trail_controller_info(class_with_id)
            super
          end

          def set_paper_trail_controller_info(class_with_id)
            klass_name, id = class_with_id.split('-', 2)
            ::PaperTrail.request.controller_info.merge!(
              source_type: klass_name,
              source_id: id,
            )
          end

        end
      end
    end
  end
  prepend Dynamic::Merge::Worker::Versioning

end
