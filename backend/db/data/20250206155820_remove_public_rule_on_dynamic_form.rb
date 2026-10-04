# frozen_string_literal: true

class RemovePublicRuleOnDynamicForm < ActiveRecord::Migration[6.0]
  def up
    global_public_rule = UneekPermission::Rule.find_by(
      receiver: UneekPermission::PredefinedReceiver::Public.instance,
      klass_name: 'Dynamic::Form',
      instance_id: nil
    )&.destroy

    Dynamic::Form.joins(:translations).where('dynamic_form_translations.human_name LIKE ?', 'EXT - %').distinct.find_each do |f|
      UneekPermission::Rule.create_with(
        permission: '_R__'
      ).find_or_create_by(
        receiver: UneekPermission::PredefinedReceiver::Public.instance,
        klass_name: 'Dynamic::Form',
        instance: f
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
