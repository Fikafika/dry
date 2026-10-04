# frozen_string_literal: true

class AddGlobalFalseToOptionsOfAddressSearchEngineFeature < ActiveRecord::Migration[8.0]
  def up
    options.update_all(global: false)
  end

  def down
    options.update_all(global: true)
  end

  def options
    Dynamic::Schema::Option::Base.joins('JOIN dynamic_schema_concerns AS owner ON owner_id = owner.id').where(
      name: ['input_mapping', 'output_mapping'],
      'owner.name': ['Address', 'City', 'ZipCode', 'State', 'County', 'Country'],
    )
  end

end
