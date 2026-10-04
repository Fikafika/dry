# frozen_string_literal: true

class AddVisibleAttributeToArticlesFromProductFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Product::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Article'}
      next unless concern.klass

      concern.klass.attrs.create_with(
        type: 'Boolean',
        human_name_fr: 'Visible',
        human_name_en: 'Visible',
      ).find_or_create_by!(name: 'visible')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
