module Dynamic
  module PhoneData
    class Worker < ::Dynamic::Record::BulkWorker
      def apply(batch)
        ::ModelDependency.with_dependencies_computed_later do
          batch.each do |record|
            record.send(:update_phone_data)
            success = record.save
            update_progress(success: success, instant: record == batch.first)
            break if progress&.canceled?
          end
        end
      end
    end
  end
end