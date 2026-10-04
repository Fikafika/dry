module Dynamic
  module DateValidity
    extend ActiveSupport::Concern
    extend Dynamic::Concern

    included do
      before_save :synchronize_validity, if: :synchronize_validity?
      before_save :delay_synchronization, if: :delay_synchronization?
    end

    class Proxy < Dynamic::Concern::Proxy

      def synchronize_validity
        current = DateTime.current
        mapping = @record.class.try(@config[:validity].pluralize)&.invert
        return unless mapping
        self.validity = if start_date_greater_than_date?(current)
          mapping[@config[:in_future_id]]
        elsif end_date_greater_than_date?(current) || has_start_date_and_no_end_date?
          mapping[@config[:ongoing_id]]
        elsif (@config[:start_date] && start_date) || (@config[:end_date] && end_date)
          mapping[@config[:past_id]]
        else
          nil
        end
      end

      def start_date_greater_than_date?(date)
        @config[:start_date] && start_date && (date < start_date)
      end

      def end_date_greater_than_date?(date)
        @config[:end_date] && end_date && (date < end_date)
      end

      def has_start_date_and_no_end_date?
        @config[:start_date] && start_date && (@config[:end_date].nil? || !end_date)
      end

      def synchronize_validity?
        (@config[:start_date] && start_date_changed?) || (@config[:end_date] && end_date_changed?)
      end

      def delay_synchronization
        mapping = @record.class.try(@config[:validity].pluralize)&.invert
        return unless mapping
        job_date = case self.validity
        when mapping[@config[:in_future_id]]
          @config[:start_date] ? self.start_date : nil
        when mapping[@config[:ongoing_id]]
          @config[:end_date] ? self.end_date : nil
        end
        if job_date
          perform_params = {
            klass_name: @record.class.name,
            id: @record.id,
            user_id: User.current&.id,
          }.deep_stringify_keys
          ::Dynamic::DateValidity::Worker::Synchronization.perform_at(job_date, perform_params)
        end
      end

      def delay_synchronization?
        mapping = @record.class.try(@config[:validity].pluralize)&.invert
        return false unless mapping
        validity.in?([mapping[@config[:in_future_id]], mapping[@config[:ongoing_id]]])
      end

      def delete_synchronization_job
        ::Sidekiq::ScheduledSet.new.scan(@record.id) do |job|
          job.delete if job.display_class == 'Dynamic::DateValidity::Worker::Synchronization'
        end
      end

    end

    module Worker
      class Synchronization
        include ::Sidekiq::Worker
        include ::Dynamic::Worker

        sidekiq_options queue: 'default', retry: 0

        def perform(args)
          schema_name = args['klass_name'].split('::')[1]
          return unless schema_name

          ::PaperTrail.request.whodunnit = args['user_id'] if args['user_id']

          ::Dynamic::Schema.load(schema_name) do
            klass = args['klass_name'].safe_constantize
            record = klass.find_by_id(args['id'])
            return unless record

            record.try(:synchronize_validity)
            record.save!
          end
        end

      end
    end

  end
end
