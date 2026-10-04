module Dynamic
  module Transaction
    module Order
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      include Dynamic::Transaction::Base

      def self.after_included(klass, concern)
        mandatory = Base::MANDATORY_CONFIG_FOR_PROXY + [:next_association]
        proxify_concern(:__transaction__, klass, concern, mandatory: mandatory)

        klass.const.include(::Dynamic::Transaction::Base::Convertible)

        c = klass.const.__transaction_config
        Dynamic::Transaction::Base.configure_proxy_basics(c, concern)

        c[:next_association] = concern.options.detect {|o| o.name == 'invoices_association'}&.value&.name
      end

      class Proxy < Dynamic::Transaction::Base::Proxy

      end

    end
  end
end