# frozen_string_literal: true

class AddMissingOptionsToDynamicPeriodFeature < ActiveRecord::Migration[8.0]


  def up
    Dynamic::Schema.find_each do |s|
      f = s.features.where(name: 'Dynamic::Period::Feature').first
      next unless f
      c = f.concern_templates.detect{|c| c.name == 'Period'}
      change_concern(c) if c

      f.concerns.where(name: 'Period').find_each do |c|
        change_concern(c)
      end
    end
  end

  def down
  end

  private

  def change_concern(c)
    options.each do |attrs|
      o = c.options.detect{|o| o.name == attrs[:name]}
      if o
        o.update!(human_name_fr: attrs[:human_name_fr], human_name_en: attrs[:human_name_en])
      else
        c.options.create!(attrs)
      end
    end
  end

  def options
    [
      {
        name: 'week',
        human_name_fr: 'Semaine',
        human_name_en: 'Week',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'week_num',
        human_name_fr: 'Attribut numéro de la semaine',
        human_name_en: 'Week number attribute',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'month_num',
        human_name_fr: 'Attribut numéro du mois',
        human_name_en: 'Month number attribute',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'quarter',
        human_name_fr: 'Trimestre',
        human_name_en: 'Quarter',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'quarter_num',
        human_name_fr: "Attribut numéro du trimestre",
        human_name_en: 'Quarter number attribute',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'half_year',
        human_name_fr: 'Semestre',
        human_name_en: 'Half year',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'half_year_num',
        human_name_fr: "Attribut numéro du semestre",
        human_name_en: 'Number attribute of half year',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      },
      {
        name: 'year_num',
        human_name_fr: "Attribut numéro de l'année",
        human_name_en: 'Year number attribute',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        global: false,
        type: 'String',
      }
    ]
  end
end