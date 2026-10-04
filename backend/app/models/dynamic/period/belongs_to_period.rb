module Dynamic
  module Period

    module BelongsToPeriod
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__belongs_to_period__, klass, concern, mandatory: [:date])
        configure_period_assoc_klasses(klass.const)
        configure_dynamic_formulas(klass.const)
      end

      def self.configure_period_assoc_klasses(klass)
        config = klass.__belongs_to_period_config
        Proxy::ASSOCS.each do |a|
          mapped = config[a]
          if mapped
            reflection = klass.reflect_on_association(mapped)
            if reflection&.has_one?
              target_klass = reflection.klass rescue nil
              if target_klass
                config[:period_klass] ||= {}
                config[:period_klass][a] = target_klass
              end
            end
          end
        end
        config.clear if !config[:period_klass] # is not considered configured if no period_klass
      end

      def self.configure_dynamic_formulas(klass)
        return unless klass.respond_to?(:attributes_for_compute_before_validation)
        config = klass.__belongs_to_period_config
        d = config[:date]
        return unless d && klass.dynamic_formulas[d]
        klass.attributes_for_compute_before_validation << d
      end

      included do
        delegate *[:assign_periods, :must_assign_periods?], to: :__belongs_to_period__
        before_validation :assign_periods, :if => :must_assign_periods?
      end

      class Proxy < Dynamic::Concern::Proxy

        ASSOCS = Dynamic::Period::Period::HIERARCHY.map{|a| :"#{a}ly_period"}.freeze

        def assign_periods
          return unless configured?

          ASSOCS.each do |a|
            klass = @config[:period_klass][a]
            next unless klass && klass < Dynamic::Period::Period
            next if send("#{a}_id_changed?")
            if date
              period_name = a.to_s.sub(/ly_period$/, '').to_sym
              r = klass.bounds_from_date(date, period_name)
              next unless r

              period = klass.create_with(
                skip_update_periods_of_records: true
              ).find_or_create_by(r)
              next unless period.valid? # how to provide error ?
              self.send("#{a}_id=", period.id)
            else
              self.send("#{a}_id=", nil)
            end
          end
        end

        def must_assign_periods?
          return configured? && date_changed?
        end

      end

    end

  end
end
