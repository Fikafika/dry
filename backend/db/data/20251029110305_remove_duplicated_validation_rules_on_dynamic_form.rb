# frozen_string_literal: true

class RemoveDuplicatedValidationRulesOnDynamicForm < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Form.find_each do |f|
      rules_to_destroy = []
      keys_for_rule_to_keep = []

      f.mandatory_validation_rules.each do |r|
        key = [r.element_ids, r.type]
        if keys_for_rule_to_keep.include?(key)
          rules_to_destroy << r
        else
          keys_for_rule_to_keep << key
        end
      end

      keys_for_rule_to_keep = []

      f.important_validation_rules.each do |r|
        key = [r.element_ids, r.type]
        if keys_for_rule_to_keep.include?(key)
          rules_to_destroy << r
        else
          keys_for_rule_to_keep << key
        end
      end

      rules_to_destroy.each(&:destroy)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
