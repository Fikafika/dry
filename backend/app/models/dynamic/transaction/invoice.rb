module Dynamic
  module Transaction
    module Invoice
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      include Dynamic::Transaction::Base

      def self.after_included(klass, concern)
        proxify_concern(:__transaction__, klass, concern, mandatory: Base::MANDATORY_CONFIG_FOR_PROXY)

        c = klass.const.__transaction_config
        Dynamic::Transaction::Base.configure_proxy_basics(c, concern)
      end

      included do
        delegate *[
          :compute_unpaid_amount
        ], to: :__transaction__

        before_validation :compute_unpaid_amount
      end

      class Proxy < Dynamic::Transaction::Base::Proxy

        def is_self_billed?
          invoice_type_code.in?(['389', '501', '500', '471', '473', '261', '502'])
        end

        def compute_unpaid_amount
          @record.unpaid_amount = @record.amount_including_vat ? @record.amount_including_vat - (@record.paid_amount || 0) : nil
        end

      end

    end
  end
end