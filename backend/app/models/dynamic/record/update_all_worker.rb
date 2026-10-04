module Dynamic
  module Record
    class UpdateAllWorker < BulkWorker

      def apply(batch)
        ::ModelDependency.with_dependencies_computed_later do
          member_params_key = :base
          batch.each do |record|
            next unless params[member_params_key]
            update_method = params[:differential] ? :differential_update : :update
            success = record.send(update_method, params[member_params_key])
            update_progress(success: success, instant: record == batch.first)
            break if progress&.canceled?
          end
        end
      end

      def scope_for_action
        :updatable_data
      end

    end
  end
end
