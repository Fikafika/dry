class AddConstraintToUneekPermissionDomain < ActiveRecord::Migration[6.0]
  def up
    execute "ALTER TABLE uneek_permission_domains ADD CONSTRAINT user_field_or_expression CHECK (context_field IS NULL OR user_field IS NULL OR (expression_method IS NULL AND expression_value IS NULL))"
  end

  def down
    execute "ALTER TABLE uneek_permission_domains DROP CONSTRAINT user_field_or_expression"
  end
end
