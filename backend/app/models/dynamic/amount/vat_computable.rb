module Dynamic
  module Amount
    module VatComputable
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__amount__, klass, concern, mandatory: [:base, :vat_rate, :amount_excluding_vat, :amount_including_vat, :vat_amount])
        c = klass.const.__amount_config

        c[:base] = concern.options.detect {|o| o.name == 'base_amount_attribute'}&.value&.name
        c[:vat_rate] = concern.options.detect {|o| o.name == 'vat_rate_association'}&.value&.name
        c[:amount_excluding_vat] = concern.options.detect {|o| o.name == 'amount_excluding_vat_attribute'}&.value&.name
        c[:amount_including_vat] = concern.options.detect {|o| o.name == 'amount_including_vat_attribute'}&.value&.name
        c[:vat_amount] = concern.options.detect {|o| o.name == 'vat_amount_attribute'}&.value&.name
        c[:quantity] = concern.options.detect {|o| o.name == 'quantity_attribute'}&.value&.name
      end

      included do
        delegate *[
          :compute_amounts,
          :compute_amounts?,
        ], to: :__amount__

        before_save :compute_amounts, if: :compute_amounts?
      end

      class Proxy < Dynamic::Concern::Proxy

        def compute_amounts
          self.amount_excluding_vat = base ? (base || 0.0) * safe_quantity : nil
          self.vat_amount = base ? compute_vat_amount : nil
          self.amount_including_vat = base ? (amount_excluding_vat || 0.0) + vat_amount : nil
        end

        def compute_amounts?
          base_changed? || (@config[:quantity] && quantity_changed?) || vat_rate_id_changed?
        end

        def safe_quantity
          @config[:quantity] ? quantity : 1
        end

        def compute_vat_amount
          result = 0.0
          if vat_rate&.percent
            value = base * vat_rate.percent * safe_quantity
            result = value.round(2)
          end
          return result
        end

      end

    end
  end
end
