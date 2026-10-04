module Dynamic
  module Record
    class DestroyAllWorker < BulkWorker

      def apply(batch)
        ::ModelDependency.with_dependencies_computed_later do
          batch.each do |record|
            success = record.destroy
            update_progress(success: success, instant: record == batch.first)
            break if progress&.canceled?
          end
        end
      end

      def scope_for_action
        :deletable_data
      end

    end
  end
end
