# frozen_string_literal: true

class UpdateCountryFeatureHumanNames < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Country::Feature'}
      next unless feature
      options_blacklist = ['name_en_attribute', 'number_attribute', 'iso_code_a3_attribute', 'iso_code_a2_attribute', 'country_klass', 'other_geo_coord', 'european_membership']
      opts = feature.options.reject {|opt| opt.name.in?(options_blacklist)}
      opts.each do |opt|
        new_human_name_fr = opt.human_name_fr.gsub('Ajout', 'Attribut')
        new_human_name_en = opt.human_name_en.gsub('Add ', '') + ' attribute'
        new_human_name_en.capitalize
        opt.update!(name: opt.name, human_name_fr: new_human_name_fr, human_name_en: new_human_name_en)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
