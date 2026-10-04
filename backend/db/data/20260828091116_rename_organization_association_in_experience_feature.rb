# frozen_string_literal: true

class RenameOrganizationAssociationInExperienceFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Experience::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Base'}
      next unless concern

      opt = concern.options.detect {|o| o.name == 'organization_association'}
      next unless opt&.value

      opt.value.update!(
        name: 'organization',
        human_name_fr: 'Organisation',
        human_name_en: 'Organization',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
