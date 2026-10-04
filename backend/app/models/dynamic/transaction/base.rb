module Dynamic
  module Transaction
    module Base
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      MANDATORY_CONFIG_FOR_PROXY = [
        :transaction_lines,
        :convert_until,
        :emit_date,
      ].freeze

      def self.after_included(klass, concern)
        proxify_concern(:__transaction__, klass, concern, mandatory: MANDATORY_CONFIG_FOR_PROXY)
        self.configure_proxy_basics(klass.const.__transaction_config, concern)

        conversion_list_klass = []
        conversion_list_klass << concern.feature.concerns.detect {|c| c.name == 'Quote'}&.klass&.name
        conversion_list_klass << concern.feature.concerns.detect {|c| c.name == 'Order'}&.klass&.name
        conversion_list_klass << concern.feature.concerns.detect {|c| c.name == 'Invoice'}&.klass&.name

        klass.const.define_singleton_method(:__transaction__conversion_list) do
          conversion_list_klass
        end

        klass.const.define_has_many_callback(:after_remove, :transaction_lines, :recompute_amount_from_association)
      end

      def self.configure_proxy_basics(proxy_config, concern)
        base_concern = concern.feature.concerns.detect {|c| c.name == 'Base'}
        proxy_config[:convert_until] = base_concern.options.detect {|c| c.name == 'convert_until_attribute'}&.value&.name
        proxy_config[:transaction_lines] = base_concern.options.detect {|c| c.name == 'transaction_lines_association'}&.value&.name
        proxy_config[:emit_date] = base_concern.options.detect {|c| c.name == 'emit_date_attribute'}&.value&.name
        proxy_config[:amount_including_vat] = base_concern.options.detect {|c| c.name == 'amount_including_vat_attribute'}&.value&.name
        proxy_config[:amount_excluding_vat] = base_concern.options.detect {|c| c.name == 'amount_excluding_vat_attribute'}&.value&.name
        proxy_config[:vat_amount] = base_concern.options.detect {|c| c.name == 'vat_amount_attribute'}&.value&.name
      end

      included do
        delegate *[
          :add_emit_date,
          :no_emit_date?,
          :compute_amounts,
          :compute_vat_breakdown,
          :compute_vat_amount_from_lines,
          :compute_fees_and_discounts,
          :recompute_amount_from_association,
          :update_from_associations,
          :update_from_associations?,
        ], to: :__transaction__

        before_validation :add_emit_date, if: :no_emit_date?
        before_save :compute_amounts

        after_commit :update_from_associations, if: :update_from_associations?
      end

      module Convertible
        extend ActiveSupport::Concern

        included do
          delegate *[
            :convert_to_next_transaction,
            :requesting_conversion?,
            :build_discounts_and_fees_from_rules,
          ], to: :__transaction__

          before_create :build_discounts_and_fees_from_rules

          after_save :convert_to_next_transaction, if: :requesting_conversion?
        end
      end

      class Proxy < Dynamic::Concern::Proxy

        attr_accessor :update_amount_after_commit

        def add_emit_date
          self.emit_date = Date.current
        end

        def no_emit_date?
          self.emit_date.nil?
        end

        def compute_amounts
          sums = compute_vat_breakdown.last
          self.amount_excluding_vat = sums[:excluding_vat]
          self.vat_amount = sums[:vat_amount]
          self.amount_including_vat = sums[:including_vat]
        end

        def build_discounts_and_fees_from_rules
          rule_klass = @record.class.module_parent::R::Transaction::ApplicableAmount::Rule
          rules = rule_klass.where(target_id: nil).order(priority: :asc).all
          rules.each do |r|
            next unless r.is_valid?(@record)
            case r.amount.type.split('::').last
            when 'Fee'
              @record.fees.build(
                owner: @record,
                name: r.amount.name,
                target_amount: r.amount,
                percent: r.amount.percent,
                raw_value: r.amount.raw_value,
                position: r.priority,
                applicability: r.applicability,
              )
            when 'Discount'
              @record.discounts.build(
                owner: @record,
                name: r.amount.name,
                target_amount: r.amount,
                percent: r.amount.percent,
                raw_value: r.amount.raw_value,
                position: r.priority,
                applicability: r.applicability,
              )
            end
          end
        end

        def convert_to_next_transaction
          baseklass_attribute_names = @record.class.superclass.dynamic_mapping.keys
          attrs = @record.slice(baseklass_attribute_names)
          discount_attribute_names = @record.class.reflect_on_association(:discounts).klass.superclass.dynamic_mapping.keys
          fee_attribute_names = @record.class.reflect_on_association(:fees).klass.superclass.dynamic_mapping.keys
          attrs.merge!(
            currency_id: @record.currency_id,
            buyer_contact_id: @record.buyer_contact_id,
            seller_company_id: @record.seller_company_id,
            buyer_company_id: @record.buyer_company_id,
            discounts_attributes: @record.discounts.map {|d| attrs = d.slice(discount_attribute_names); attrs.merge!(owner: @record)},
            fees_attributes: @record.fees.map {|d| d.slice(fee_attribute_names); attrs.merge!(owner: @record)}
          )
          attrs.merge!(transaction_lines_attributes: gather_transaction_lines_attributes(transaction_lines, transaction_lines_attribute_names))
          next_association.create!(attrs)
        end

        def requesting_conversion?
          convert_until_previously_changed? && forward_conversion? && line_type(@record).in?(conversion_list)
        end

        def forward_conversion?
          next_index = transaction_index(convert_until)
          klass_index = transaction_index(line_type(@record))
          return false unless next_index && klass_index
          current_index = transaction_index(convert_until_previously_was) || 0
          return current_index < next_index && klass_index < next_index
        end

        def transaction_index(type)
          return type ? conversion_list.index(type.capitalize) : nil
        end

        def conversion_list
          @record.class.__transaction__conversion_list
        end

        def transaction_lines_attribute_names
          @record.class.reflect_on_association(@config[:transaction_lines].to_sym).klass.dynamic_mapping.keys
        end

        def gather_transaction_lines_attributes(lines, attribute_names)
          result = []
          lines.each do |tl|
            attrs = tl.slice(attribute_names)
            if tl.sublines.any?
              attrs.merge!(sublines_attributes: gather_transaction_lines_attributes(tl.sublines, attribute_names))
            end
            attrs[:vat_rate] = tl.vat_rate if tl.vat_rate
            result << attrs
          end
          return result
        end

        # Sum of vat amount from each lines
        def compute_vat_amount_from_lines
          amounts = []
          lines = transaction_lines.select {|tl| tl.parent_id == nil}
          compute_vat_for_lines(lines, amounts) do |r, l|
            r[:excluding_vat] = (r[:excluding_vat] + l.amount_excluding_vat).round(2)
            r[:vat_amount] = (r[:vat_amount] + l.vat_amount).round(2)
            r[:including_vat] = (r[:including_vat] + l.amount_including_vat).round(2)
          end
          return amounts
        end

        # For each vat percentage, compute vat amount from sum of line's amount (excluding vat) having the same vat percentage
        def compute_vat_breakdown
          amounts = []
          lines = transaction_lines.select {|tl| tl.parent_id == nil}

          compute_vat_for_lines(lines, amounts) do |r, l|
            r[:excluding_vat] = l.amount_excluding_vat ? (r[:excluding_vat] + l.amount_excluding_vat).round(2) : 0
          end

          sum = {excluding_vat: 0.0, vat_amount: 0.0, including_vat: 0.0}
          amounts.each do |a|
            if a[:percent]
              raw_vat_amount = a[:excluding_vat] * a[:percent]
              a[:vat_amount] = raw_vat_amount.round(2)
            else
              a[:vat_amount] = 0
            end
            a[:including_vat] = (a[:excluding_vat] + a[:vat_amount]).round(2)
            sum[:excluding_vat] = (sum[:excluding_vat] + a[:excluding_vat]).round(2)
            sum[:including_vat] = (sum[:including_vat] + a[:including_vat]).round(2)
            sum[:vat_amount] = (sum[:vat_amount] + a[:vat_amount]).round(2)
          end

          sum[:excluding_vat_before_discounts] = sum[:excluding_vat]
          discounts_amount = @record.discounts.sort_by {|d| d.position}.inject(0) do |r, d|
            r + d.apply_amount_to_value(sum[:excluding_vat], sum[:excluding_vat] + r)
          end
          sum[:excluding_vat] = (sum[:excluding_vat] + discounts_amount).round(2)

          sum[:excluding_vat_before_fees] = sum[:excluding_vat]
          fees_amount = @record.fees.sort_by {|f| f.position}.inject(0) do |r, f|
            r + f.apply_amount_to_value(sum[:excluding_vat], sum[:excluding_vat] + r)
          end
          sum[:excluding_vat] = (sum[:excluding_vat] + fees_amount).round(2)

          sum[:including_vat] = (sum[:excluding_vat] + sum[:vat_amount]).round(2)

          amounts << sum
          return amounts
        end

        def compute_vat_for_lines(lines, result, &block)
          lines.each do |l|
            if l.net_unit_price && !line_type(l).in?(['TransactionLineInfo', 'TransactionLineGroup'])
              rslt = result.detect do |r|
                r[:percent] == l.vat_rate&.percent && r[:code] == l.vat_rate&.code
              end
              unless rslt
                rslt = {percent: l.vat_rate&.percent, code: l.vat_rate&.code, hint: nil, excluding_vat: 0.0, vat_amount: 0.0, including_vat: 0.0}
                if l.vat_rate
                  rslt[:hint] = l.vat_rate.class.human_attribute_value(:code, l.vat_rate.code)
                end
                result << rslt
              end
              block.call(rslt, l)
            end
            compute_vat_for_lines(l.sublines, result, &block)
          end
        end

        def line_type(line)
          line.type.demodulize
        end

        def compute_fees_and_discounts
          result = {fees_amount: 0, discounts_amount: 0}
          transaction_lines.each do |tl|
            next unless line_type(tl) == 'TransactionLine'
            r = tl.compute_fees_and_discounts
            result[:fees_amount] += r[:fees_amount]
            result[:discounts_amount] += r[:discounts_amount]
          end
          return result
        end

        def update_from_associations
          @record.instance_variable_set(:@must_save, nil)
          @record.compute_amounts
          @record.save! if @record.changed?
        end

        def update_from_associations?
          @record.instance_variable_get(:@must_save)
        end

        def recompute_amount_from_association(record)
          if @record.persisted?
            @record.instance_variable_set(:@must_save, !@record.changed?)
          end
        end

      end

    end
  end
end
