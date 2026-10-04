# frozen_string_literal: true

class AddIndisponibilityModuleToEventFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema::Feature.where(name: 'Dynamic::Event::Feature').find_each do |f|
      f.update!(human_name_fr: 'Evènement') if f.name == 'Evénnement'
      f.concerns.select {|c| c.human_name_fr == 'Evénnement'}.each {|c| c.update!(human_name_fr: 'Evènement')}
      next if f.concern_templates.count == 2
      f.concern_templates.create_with(
        human_name_fr: 'Indisponibilité',
        human_name_en: 'Indisponibility',
        template: true,
        options_attributes: [
          {
            name: 'indisponibility_assoc',
            human_name_fr: 'Association des indisponibilitées',
            human_name_en: 'Indisponibility association',
            type: 'String',
            coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
            value: ''
          },
          {
            name: 'event_klass',
            human_name_fr: "Table évennement ciblé par l'association",
            human_name_en: 'Evant table targettted by association',
            type: 'String',
            coder_type: 'Dynamic::Schema::Option::Coder::Klass',
            value: ''
          },
        ],
      ).find_or_create_by!(name: 'Indisponibility')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
