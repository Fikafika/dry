module Dynamic
  module Experience
    module Worker
      class FinishPrevious
        include ::Sidekiq::Worker
        include ::Dynamic::Worker

        sidekiq_options queue: 'low', retry: 0

        REQUIRED_ARGS = ['klass_name', 'id', 'date_current'].freeze

        def perform(args)
          unless REQUIRED_ARGS.all? { |key| args.key?(key) }
            Rails.logger.error("FinishPreviousWorker could not be processed due to missing args. Current args : #{args}")
            return
          end

          @schema_name = args['klass_name'].split('::')[1]
          return unless @schema_name

          ::PaperTrail.request.whodunnit = args['user_id'] if args['user_id']

          ::Dynamic::Schema.load(@schema_name) do
            exp_klass = args['klass_name'].constantize
            exp = exp_klass.find_by_id(args['id'])
            return unless exp
            proxy = exp.__experience__
            return unless proxy && proxy.owner
            experiences = proxy.owner.__experience__.experiences
            finish_previous_attribute_name = exp_klass.__experience_config[:finish_previous]
            last_exp = experiences.where("#{finish_previous_attribute_name}": true).order('created_at').last
            return unless last_exp

            experiences&.each do |e|
              next if e == last_exp
              e_proxy = e.__experience__
              next unless e_proxy.ongoing
              e_proxy.skip_experience_callbacks = true
              e_proxy.ongoing = false
              e_proxy.main_company = false
              e_proxy.end_date = args['date_current']
              e.save!
            end

            last_exp.__experience__.finish_previous = false
            last_exp.save!
          end
        end
      end
    end
  end
end
