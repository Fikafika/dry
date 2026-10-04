# frozen_string_literal: true

class UpdateExperienceFeatureConcerns < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Experience::Feature'}

      feature.concerns.each do |c|
        next if c.name == 'Experience'
        default_value = if c.klass
          true
        else
          c.name == 'Job' ? true : false
        end
        c.options.create_with(
          human_name_fr: 'Créer la table',
          human_name_en: 'Create table',
          type: 'Boolean',
          value: default_value,
        ).find_or_create_by!(name: 'activate')
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
