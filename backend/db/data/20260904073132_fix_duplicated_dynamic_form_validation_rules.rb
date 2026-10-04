# frozen_string_literal: true

class FixDuplicatedDynamicFormValidationRules < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |s|
      s.load
      s.forms.includes(mandatory_validation_rules: {}, important_validation_rules: {}).find_each do |f|
        m = f.mandatory_validation_rules.map{|r| [r.element_ids, r.type]}
        todo = (m.length != m.uniq.length)
        unless todo
          m = f.important_validation_rules.map{|r| [r.element_ids, r.type]}
          todo = (m.length != m.uniq.length)
        end
        if todo
          f.mandatory_validation_rules.destroy_all
          f.important_validation_rules.destroy_all
          f.update_validation_rules_from_elements
        end
      end
    end
  end

  def down
  end
end
