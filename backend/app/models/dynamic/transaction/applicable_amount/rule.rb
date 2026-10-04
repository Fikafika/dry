module Dynamic
  module Transaction
    module ApplicableAmount

      class Rule < ActiveRecord::Base
        self.table_name = 'applicable_amount_rules'

        include Dynamic::Mount

        define_table do |t| # if you change this definition you must do a migration of all mounted tables
          t.string     :human_name, translate: true
          t.integer    :priority
          t.integer    :applicability
          t.belongs_to :amount, type: :uuid
          t.belongs_to :target, type: :uuid
        end

        after_mount do
          enum :applicability , {
            on_base: 0,
            previous_operation: 1,
          }

          validates :priority, :applicability, presence: true

          schema_const_name = self.module_parent.module_parent.module_parent.module_parent.name
          belongs_to :amount, class_name: "#{schema_const_name}::Amount"
          belongs_to :target, class_name: "#{schema_const_name}::Product", optional: true
          has_many :conditions, class_name: 'Condition', inverse_of: :rule, foreign_key: 'rule_id', dependent: :destroy

          accepts_nested_attributes_for :conditions, allow_destroy: true
        end

        def is_valid?(record)
          return false if amount&.validity_start && (Time.now < amount.validity_start)
          return false if amount&.validity_end && (Time.now > amount.validity_end)
          return conditions.all? {|c| c.applicable_to?(record)}
        end

      end

    end
  end
end
