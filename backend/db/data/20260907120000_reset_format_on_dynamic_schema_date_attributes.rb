class ResetFormatOnDynamicSchemaDateAttributes < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema::Attribute::Base.with_deleted
      .where(type: ['Date', 'DateTime'])
      .update_all(format: nil, format_options: {})
  end

  def down
  end
end
