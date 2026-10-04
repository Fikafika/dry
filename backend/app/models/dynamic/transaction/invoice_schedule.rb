module Dynamic
  module Transaction
    module InvoiceSchedule
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__invoice_schedule__, klass, concern)
      end

      included do
        delegate *[
          :set_amount,
          :set_date_numbers,
          :set_due_date_count,
          :begin_at_before_first_due_date,
          :amount_does_not_exceed_order_amount,
          :due_date_count_positive,
          :due_date_organization_is_possible,
          :generate_all_due_dates,
          :generate_all_due_dates?,
          :generate_first_due_date,
          :generate_first_due_date?,
          :cancel_due_dates,
          :cancel_due_dates?,
        ], to: :__invoice_schedule__

        before_validation :set_amount
        before_validation :set_date_numbers
        before_validation :set_due_date_count
        validate :begin_at_before_first_due_date
        validate :amount_does_not_exceed_order_amount
        validate :due_date_count_positive
        validate :due_date_organization_is_possible

        after_create :generate_first_due_date, if: :generate_first_due_date?
        after_save :generate_all_due_dates, if: :generate_all_due_dates?
        after_save :cancel_due_dates, if: :cancel_due_dates?
      end

      class Proxy < Dynamic::Concern::Proxy

        def generate_next
          return unless @record.kind == 'subscription'
          previous = @record.due_dates.sort {|a, b| a.position <=> b.position}.last
          return unless previous&.position && previous.scheduled_date < DateTime.current
          next_date = compute_date(previous.position)
          return unless processable?(next_date)
          return unless @record.due_dates.detect {|d| d.scheduled_date == next_date}.nil?
          @record.due_dates.create!(
            amount: @record.amount,
            scheduled_date: next_date,
            position: previous.position + 1
          )
        end

        def set_amount
          @record.amount = @record.order.__transaction__.amount_including_vat if @record.order
        end

        def set_date_numbers
          case @record.recurrency
          when 'yearly'
            @record.month_number ||= 1
            @record.monthday_number ||= 1
          when 'monthly'
            @record.monthday_number ||= 1
          when 'weekly'
            @record.weekday_number ||= 1
          end
        end

        def set_due_date_count
          return unless @record.kind == 'payment_in_installments'
          return unless @record.max_amount_per_due_date && @record.max_amount_per_due_date > 0
          @record.due_date_count = (@record.amount / @record.max_amount_per_due_date).floor
        end

        def begin_at_before_first_due_date
          @record.errors.add(:begin_at, :invalid) if @record.begin_at.nil? || compute_date(0) < @record.begin_at
        end

        def amount_does_not_exceed_order_amount
          @record.errors.add(:amount, :invalid) if @record.order && @record.amount > @record.order.__transaction__.amount_including_vat
        end

        def due_date_count_positive
          if @record.kind != 'subscription' && (@record.due_date_count.nil? || (@record.due_date_count <= 0))
            @record.errors.add(:due_date_count, :invalid)
          end
        end

        def due_date_organization_is_possible
          if @record.max_amount_per_due_date && (@record.due_date_count * @record.max_amount_per_due_date) > @record.amount
            @record.errors.add(:max_amount_per_due_date, :invalid)
            @record.errors.add(:due_date_count, :invalid)
          end
        end

        def generate_first_due_date
          @record.due_dates.create!(
            amount: @record.amount,
            scheduled_date: compute_date(0),
            position: 1,
          )
        end

        def generate_first_due_date?
          return @record.kind == 'subscription' && @record.due_dates.empty?
        end

        def generate_all_due_dates
          due_date_attrs = []
          if @record.max_amount_per_due_date
            quotient = @record.max_amount_per_due_date
            remainder = @record.amount - (quotient * @record.due_date_count)
          else
            quotient = (@record.amount / @record.due_date_count).round(2)
            remainder = (@record.amount % @record.due_date_count).round(2)
          end

          (0...@record.due_date_count).each do |i|
            date = compute_date(i)
            break if @record.finish_at && (date >= @record.finish_at)
            due_date_attrs << {
              amount: quotient,
              scheduled_date: date,
              position: i + 1,
            }
          end

          if remainder > 0
            due_date_attrs << {
              amount: remainder,
              scheduled_date: compute_date(due_date_attrs.length + 1),
            }
          end

          @record.due_dates.create!(due_date_attrs)
        end

        def generate_all_due_dates?
          return false unless in_progress?
          return false unless @record.due_date_count && @record.due_date_count > 0
          return @record.kind == 'payment_in_installments' && @record.due_dates.empty?
        end

        def cancel_due_dates
          @record.due_dates.each do |d|
            next unless d.validity == 'in_future'
            d.update!(canceled: true)
          end
        end

        def cancel_due_dates?
          @record.canceled_previously_changed?(to: true)
        end

        private

        def compute_date(i)
          case @record.recurrency
          when 'yearly'
            result = @record.begin_at.advance(years: i)
            result = @record.begin_at.change(month: @record.month_number)
            day = safe_monthday_number(result.end_of_month.mday)
            if result.mday < day
              result = result.advance(days: day - result.mday)
            end
          when 'monthly'
            result = @record.begin_at.advance(months: i)
            day = safe_monthday_number(result.end_of_month.mday)
            if result.mday < day
              result = result.advance(days: day - result.mday)
            end
          when 'weekly'
            result = @record.begin_at.advance(weeks: i)
            days = result.cwday > @record.weekday_number ? 7 - result.cwday + @record.weekday_number : result.cwday - @record.weekday_number
            result = result.advance(days: days)
          when 'daily'
            result = @record.begin_at.advance(days: i)
          end

          return result
        end

        def safe_monthday_number(last_day_of_month)
          return @record.monthday_number > last_day_of_month ? last_day_of_month : @record.monthday_number
        end

        def in_progress?
          return processable?(DateTime.current)
        end

        def processable?(time)
          return false if @record.finish_at && @record.finish_at >= time
          return @record.begin_at < time
        end
      end

    end
  end
end