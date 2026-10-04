# frozen_string_literal: true

class UpdateKnewsletterFeatureKlasses < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled

      option = feature.options.detect {|o| o.name == 'newsletter_klass_name'}
      newsletter_klass = schema.klasses.detect {|k| k.name == option.value}
      option = feature.options.detect {|o| o.name == 'link_klass_name'}
      link_klass = schema.klasses.detect {|k| k.name == option.value}
      option = feature.options.detect {|o| o.name == 'visit_klass_name'}
      visit_klass = schema.klasses.detect {|k| k.name == option.value}

      if visit_klass
        visit_klass.update!(name_attribute: visit_klass.attrs.detect {|a| a.name == 'date'})
      end

      unless newsletter_klass && link_klass
        Rails.logger.warn("Cannot migrate due to missing klasses")
        next
      end

      link_klass.attrs.detect {|a| a.name == 'type_de_lien'}&.destroy!

      link_klass.attrs.create_with(
        human_name_fr: 'Catégorie',
        human_name_en: 'Category',
        type: 'Enum',
        values_attributes: [
          {
            name: 'opening',
            human_name_fr: 'Ouverture',
            human_name_en: 'Opening',
          },
          {
            name: 'unsubscribe',
            human_name_fr: 'Désinscription',
            human_name_en: 'Unsubscribe',
          }
        ]
      ).find_or_create_by!(name: 'category')

      update_formula(link_klass, 'unique_click_percentage_by_opening', 'if(category = "opening"; unique_click_percentage; min(round(unique_click * 100.0 / newsletter.unique_opening; 2); 100.0))')

      update_formula(link_klass, 'unique_click_percentage', 'min(round(unique_click * 100.0 / newsletter.num_recipients; 2); 100.0)')

      update_formula(link_klass, 'click', nil)

      link_klass.update!(name_attribute: link_klass.attrs.detect {|a| a.name == 'url'})

      update_formula(newsletter_klass, 'unsubscribed_percentage', 'nth(select(links.unique_click_percentage; links.category = "unsubscribe"); 0)')

      update_formula(newsletter_klass, 'unsubscribe', 'nth(select(links.click; links.category = "unsubscribe"); 0)')

      update_formula(newsletter_klass, 'unique_opening_percentage', 'nth(select(links.unique_click_percentage; links.category = "opening"); 0)')

      update_formula(newsletter_klass, 'unique_opening', 'nth(select(links.unique_click; links.category = "opening"); 0)')

      update_formula(newsletter_klass, 'opening', 'nth(select(links.click; links.category = "opening"); 0)')

      newsletter_klass.update!(name_attribute: newsletter_klass.attrs.detect {|a| a.name == 'name'})
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def update_formula(klass, attr_name, formula)
    attr = klass.attrs.detect {|a| a.name == attr_name}
    attr&.update!(formula: formula)
  end
end
