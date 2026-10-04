module Dynamic
  module Transaction

    module Feature; extend ActiveSupport::Concern

      def self.load_constants(schema)
        applicable_amount_rule_klass = schema.const_reserved_klass('Transaction::ApplicableAmount::Rule', ::Dynamic::Transaction::ApplicableAmount::Rule)
        amount_klass = schema.klasses.detect {|k| k.name == 'Amount'}
        product_klass = schema.klasses.detect {|k| k.name == 'Product'}

        applicable_amount_rule_klass.belongs_to(:amount, class_name: amount_klass.const_absolute_name)
        applicable_amount_rule_klass.belongs_to(:target, class_name: product_klass.const_absolute_name)
      end

    end

    module AppliedAmount
    end

    module Base
    end

    module Invoice
    end

    module Quote
    end

    module Order
    end

    module Line
      module Base
      end

      module Group
      end

      module Info
      end
    end

    module InvoiceSchedule
    end

    module InvoiceDueDate
    end

  end
end
