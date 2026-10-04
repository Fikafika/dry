# frozen_string_literal: true

class AddMainContactAttributeToExperienceFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Experience::Feature'}
      next unless feature
      concern = feature.concerns.detect {|c| c.name == 'Experience'}
      next unless concern
      concern.options.create_with(
        human_name_fr: 'Attribut contact principal',
        human_name_en: 'Main contact attribute',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: ''
      ).find_or_create_by!(
        name: 'main_contact_attribute',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
