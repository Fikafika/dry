module Dynamic
  module Transaction
    module Line
      module Group
        extend ActiveSupport::Concern
        extend Dynamic::Concern

        include Dynamic::Transaction::Line::Base

        def self.after_included(klass, concern)
          proxify_concern(:__transaction_line__, klass, concern)
        end

        class Proxy < Dynamic::Transaction::Line::Base::Proxy

          def compute_amounts
            @record.vat_rate = nil
            @record.vat_amount = 0
            @record.amount_excluding_vat = 0
            @record.amount_including_vat = 0
            compute_sublines_amount(@record.sublines)
          end

          def compute_sublines_amount(sublines)
            sublines.each do |s|
              next if s.type.demodulize == 'TransactionLineInfo'
              s.compute_quantity
              s.compute_amounts
              s.save! if s.changed?
              @record.amount_excluding_vat += s.amount_excluding_vat || 0
              @record.amount_including_vat += s.amount_including_vat || 0
              @record.vat_amount += s.vat_amount || 0
              compute_sublines_amount(s.sublines) unless s.type.demodulize == 'TransactionLineGroup'
            end
          end

          def update_parent?
            @record.parent_id_previously_changed? || (@record.parent_id && @record.amount_including_vat_previously_changed?)
          end

          def update_transaction?
            @record.owner_transaction && @record.amount_including_vat_previously_changed? && !update_parent?
          end

        end

      end
    end
  end
end
