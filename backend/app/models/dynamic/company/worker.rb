module Dynamic
  module Company
    class Worker < ::Dynamic::Record::BulkWorker
      def apply(batch)
        batch.each do |establissement|
          success = true
          begin
            establissement.__organization_establissement__.match_organization
          rescue ActiveRecord::RecordInvalid => e
            success = false
            logger.error("Dynamic::Company::Worker failed to match #{establissement.class.name}##{establissement.id}: #{e.message}")
          end
          update_progress(success: success, instant: establissement == batch.first)
          break if progress&.canceled?
        end
      end
    end
  end
end
