module Dynamic
  module Transaction
    module InvoiceDueDate
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      include Dynamic::DateValidity

      delegate *[
        :synchronize_validity,
        :synchronize_validity?,
        :delay_synchronization,
        :delay_synchronization?,
        :delete_synchronization_job
      ], to: :__invoice_due_date__

      def self.after_included(klass, concern)
        proxify_concern(:__invoice_due_date__, klass, concern, mandatory: [:start_date, :invoice, :validity, :in_future_id, :ongoing_id, :past_id])

        c = klass.const.__invoice_due_date_config

        c[:invoice] = concern.options.detect{|o| o.name == 'invoice_association'}&.value&.name
        c[:start_date] = concern.options.detect{|o| o.name == 'begin_attribute'}&.value&.name
        c[:validity] = concern.options.detect{|o| o.name == 'validity_attribute'}&.value&.name
        c[:in_future_id] = concern.options.detect{|o| o.name == 'in_future_enum_value_id'}&.value
        c[:ongoing_id] = concern.options.detect{|o| o.name == 'ongoing_enum_value_id'}&.value
        c[:past_id] = concern.options.detect{|o| o.name == 'past_enum_value_id'}&.value
      end

      included do
        delegate *[
          :generate_invoice,
          :generate_invoice?,
          :generate_next,
          :generate_next?,
          :delete_job?,
        ], to: :__invoice_due_date__

        after_commit :generate_invoice, if: :generate_invoice?
        after_commit :generate_next, if: :generate_next?
        after_commit :delete_synchronization_job, if: :delete_job?
      end

      class Proxy < DateValidity::Proxy

        def generate_invoice
          invoice_attrs = {'emit_date' => DateTime.current}
          invoice_attrs['invoice_order_ids'] = [@record.schedule.order_id] if @record.schedule.order

          case @record.schedule.kind
          when 'payment_in_installments'
            if @record.schedule.targeted_line
              invoice_attrs['transaction_lines_attributes'] = [
                {
                  'label' => @record.schedule.line_prefix ? "#{@record.schedule.line_prefix} - #{@record.schedule.targeted_line.label}" : @record.schedule.targeted_line.label,
                  'net_unit_price' => @record.amount,
                  'reference_id' => @record.schedule.targeted_line_id,
                }
              ]
            else
              invoice_attrs['transaction_lines_attributes'] = [
                {
                  'label' => @record.schedule.name, # meh
                  'net_unit_price' => @record.amount,
                }
              ]
            end
          when 'subscription'
            invoice_attrs['transaction_lines'] = [@record.schedule.targeted_line] if @record.schedule.targeted_line
          end

          @record.update!("#{@config[:invoice]}_attributes" => invoice_attrs)
        end

        def generate_invoice?
          !is_canceled? && @record.invoice.nil? && start_date && start_date <= DateTime.current
        end

        def is_canceled?
          @record.schedule.nil? || @record.schedule.canceled || @record.canceled
        end

        def generate_next
          @record.schedule.reload.__invoice_schedule__.generate_next
        end

        def generate_next?
          !is_canceled? && @record.schedule.kind == 'subscription'
        end

        def delete_job?
          # ActiveModel::Dirty did not register any changes here
          @record.canceled || @record.invoice
        end

      end
    end
  end
end
