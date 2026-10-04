module Dynamic
  module Transaction
    module Line
      module Info
        extend ActiveSupport::Concern
        extend Dynamic::Concern

        include Dynamic::Transaction::Line::Base

        def self.after_included(klass, concern)
          proxify_concern(:__transaction_line__, klass, concern)
        end

        class Proxy < Dynamic::Transaction::Line::Base::Proxy

        end

      end
    end
  end
end
