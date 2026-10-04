module Dynamic
  module Period

    module Period
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      HIERARCHY = [
        :week,
        :month,
        :quarter,
        :half_year,
        :year,
      ].freeze

      def self.after_included(klass, concern)
        proxify_concern(:__period__, klass, concern, mandatory: [:begin_at, :finish_at])
        configure_klasses_belongs_to_period(klass, concern)
        configure_next_period(klass)
        configure_klasses_of_numbered_records(klass)
        configure_dynamic_formulas(klass)
      end

      private

      def self.configure_klasses_belongs_to_period(klass, concern)
        c = klass.const.__period_config
        return unless c.any?

        c[:klasses_belongs_to_period] = concern.feature.concerns.select do |c|
          c.name == 'BelongsToPeriod'
        end.map(&:klass).compact.map(&:const)
      end

      def self.configure_next_period(klass)
        c = klass.const.__period_config
        return unless c[:previous_period]

        inverse = klass.const.reflect_on_association(c[:previous_period])&.inverse_reflection
        return unless inverse && inverse.has_one?

        c[:next_period] = inverse.name
      end

      def self.configure_klasses_of_numbered_records(klass)
        c = klass.const.__period_config

        HIERARCHY.each do |h|
          next unless c[h]
          reflection = klass.const.reflect_on_association(c[h])
          if reflection&.has_one?
            c[:"#{h}_klass"] = reflection.klass rescue nil
          end
        end
      end

      def self.configure_dynamic_formulas(klass)
        return unless klass.const.respond_to?(:attributes_for_compute_before_validation)
        c = klass.const.__period_config
        return unless c[:finish_at] && klass.const.dynamic_formulas[c[:finish_at]]
        klass.const.attributes_for_compute_before_validation << c[:finish_at]
      end

      included do
        # TODO validate uniqness

        delegate *[
          :update_periods_of_records,
          :must_update_periods_of_records?,
          :skip_update_periods_of_records,
          :skip_update_periods_of_records=,
          :assign_previous_and_next_periods,
          :assign_numbered_records,
        ], to: :__period__

        before_validation :assign_previous_and_next_periods
        before_validation :assign_numbered_records

        after_save :update_periods_of_records, :if => :must_update_periods_of_records?
      end

      class_methods do

        def bounds_from_date(date, period_name)
          c = __period_config
          return unless c && c[:begin_at] && c[:finish_at]

          case period_name
          when :quarter
            b, f = bounds_for_year_divided_by(date, 4)
            return { c[:begin_at] => b, c[:finish_at] => f }
          when :half_year
            b, f = bounds_for_year_divided_by(date, 2)
            return { c[:begin_at] => b, c[:finish_at] => f }
          when :week, :month, :year
            b = date.send("beginning_of_#{period_name}")
            f = date.send("end_of_#{period_name}")
            return { c[:begin_at] => b, c[:finish_at] => f }
          else
            return nil
          end
        end

        private

        def bounds_for_year_divided_by(date, divider)
          d = 12 / divider # eg. 3 if divided by 4
          r = ((date.month - 1) / d) + 1 # eg. 2 if month == 5
          first_month = (r * d) - d + 1 # eg. 4 if month == 5
          return [
            Date.new(date.year, first_month, 1),
            Date.new(date.year, first_month + d - 1, 1).end_of_month
          ]
        end

      end

      class Proxy < Dynamic::Concern::Proxy
        attr_accessor :skip_update_periods_of_records

        def update_periods_of_records
          return unless configured?

          if begin_at_previously_was && finish_at_previously_was
            for_each_klass_that_belongs_to_period do |klass, date_attr, period_assoc|
              import_options = {on_duplicate_key_update: klass.column_names - ['created_at', 'updated_at']}
              klass.where("#{date_attr} >= '#{begin_at_previously_was}' AND #{date_attr} <= '#{finish_at_previously_was}'").where(period_assoc => @record).find_in_batches do |batch|
                batch = batch.select do |r|
                  r.assign_periods
                  r.changed?
                end
                klass.import(batch, **import_options) if batch.any?
              end
            end
          end

          if !@record.deleted? && begin_at && finish_at
            for_each_klass_that_belongs_to_period do |klass, date_attr, period_assoc|
              t = klass.table_name
              klass.where("#{t}.#{date_attr} >= '#{begin_at}' AND #{t}.#{date_attr} <= '#{finish_at}'").with_no_associated(period_assoc).find_in_batches do |batch|
                import_options = {on_duplicate_key_update: klass.column_names - ['created_at', 'updated_at']}
                batch.each do |r|
                  r.send("#{period_assoc}=", @record)
                end
                klass.import(batch, **import_options)
              end
            end
          end

        end

        def for_each_klass_that_belongs_to_period
          @config[:klasses_belongs_to_period].each do |klass|
            c = klass.__belongs_to_period_config
            date_attr = c[:date]
            next unless date_attr
            Dynamic::Period::BelongsToPeriod::Proxy::ASSOCS.each do |a|
              next unless c[a] && c[:period_klass][a] == @record.class
              yield(klass, date_attr, c[a])
            end
          end
        end

        def must_update_periods_of_records?
          return configured? && !skip_update_periods_of_records && (begin_at_previously_changed? || finish_at_previously_changed?)
        end

        def assign_previous_and_next_periods
          return unless configured?

          if @config[:previous_period] && begin_at_changed?
            if begin_at
              prev = @record.class.where(@config[:finish_at] => begin_at - 1.day).first
              self.previous_period_id = prev&.id
            else
              self.previous_period_id = nil
            end
          end

          if @config[:next_period] && finish_at_changed?
            if finish_at
              next_ = @record.class.where(@config[:begin_at] => finish_at + 1.day).first
              self.next_period_id = next_&.id
            else
              self.next_period_id = nil
            end
          end
        end

        def assign_numbered_records
          return unless configured? && (begin_at_changed? || finish_at_changed?)

          if @config[:week_klass] && @config[:week_num]
            if begin_at && finish_at && begin_at.cweek == finish_at.cweek && begin_at.year == finish_at.year
              r = @config[:week_klass].find_or_create_by(@config[:week_num] => begin_at.cweek)
              self.week_id = r&.id
            else
              self.week_id = nil
            end
          end

          if @config[:month_klass] && @config[:month_num]
            if begin_at && finish_at && begin_at.month == finish_at.month && begin_at.year == finish_at.year
              r = @config[:month_klass].find_or_create_by(@config[:month_num] => begin_at.month)
              self.month_id = r&.id
            else
              self.month_id = nil
            end
          end

          if @config[:quarter_klass] && @config[:quarter_num]
            if begin_at && finish_at && begin_at.quarter == finish_at.quarter && begin_at.year == finish_at.year
              r = @config[:quarter_klass].find_or_create_by(@config[:quarter_num] => begin_at.quarter)
              self.quarter_id = r&.id
            else
              self.quarter_id = nil
            end
          end

          if @config[:half_year_klass] && @config[:half_year_num]
            if begin_at && finish_at && (begin_at.month <= 6) == (finish_at.month <= 6) && begin_at.year == finish_at.year
              r = @config[:half_year_klass].find_or_create_by(@config[:half_year_num] => (begin_at.month <= 6 ? 1 : 2))
              self.half_year_id = r&.id
            else
              self.half_year_id = nil
            end
          end

          if @config[:year_klass] && @config[:year_num]
            if begin_at && finish_at && begin_at.year == finish_at.year
              r = @config[:year_klass].find_or_create_by(@config[:year_num] => begin_at.year)
              self.year_id = r&.id
            else
              self.year_id = nil
            end
          end
        end
      end

    end

  end
end
