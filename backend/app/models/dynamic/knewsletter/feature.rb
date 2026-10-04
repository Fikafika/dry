module Dynamic
  module Knewsletter
    module Feature; extend Dynamic::Feature

      DEPENDENCIES = [
        'Dynamic::RecipientInfo::Feature',
      ].freeze

      def self.feature_attributes
        {
          human_name_fr: 'Newsletter',
          human_name_en: 'Newsletter',
          mandatory: false,
          visible: false,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Newsletter',
              human_name_fr: 'Newsletter',
              human_name_en: 'Newsletter',
            },
            {
              name: 'Link',
              human_name_fr: 'Lien newsletter',
              human_name_en: 'Newsletter link',
            },
            {
              name: 'Visit',
              human_name_fr: 'Visite Newsletter',
              human_name_en: 'Newsletter visit',
            },
            {
              name: 'NewsletterDelivery',
              human_name_fr: 'Livraison Newsletter',
              human_name_en: 'Newsletter delivery',
            },
          ],
          options_attributes: [
            {
              name: 'elasticsearch_indices_already_created',
              human_name_en: 'Elasticsearch indices already created',
              human_name_fr: "Creation des index elasticsearch effectuée",
              type: 'Boolean',
              value: false
            },
            {
              name: 'theme_klass',
              human_name_fr: 'Table des thèmes de newsletter',
              human_name_en: "Newsletter theme table",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: nil
            },
            {
              name: 'theme_associations_klasses',
              human_name_en: 'Classes with theme associations',
              human_name_fr: 'Classes avec associations thèmes',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klasses',
              value: ''
            }
          ],
        }
      end

      def self.after_enabled(feature)
        DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_or_create_by!(name: d)
          unless dependency.enabled
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end

        self.create_klasses(feature)
      end

      def self.after_enabled_and_commit_schema(feature)
        newsletter_klass = feature.concerns.detect {|c| c.name == 'Newsletter'}.klass
        newsletter_klass.update!(name_attribute: newsletter_klass.attrs.detect {|a| a.name == 'name'})

        link_klass = feature.concerns.detect {|c| c.name == 'Link'}.klass
        link_klass.update!(name_attribute: link_klass.attrs.detect {|a| a.name == 'url'})

        visit_klass = feature.concerns.detect {|c| c.name == 'Visit'}.klass
        visit_klass.update!(name_attribute: visit_klass.attrs.detect {|a| a.name == 'date'})

        delivery_klass = feature.concerns.detect {|c| c.name == 'NewsletterDelivery'}.klass
        delivery_klass.update!(name_attribute: delivery_klass.attrs.detect {|a| a.name == 'delivery_date'})

        theme_klass = feature.options.detect {|c| c.name == 'theme_klass'}.value
        theme_klass.update!(name_attribute: theme_klass.attrs.detect {|a| a.name == 'name'})

        remove_large_associations_from_edit_in_place_forms(newsletter_klass, link_klass, visit_klass)
      end

      def self.create_klasses(feature)
        concern = feature.concerns.detect {|c| c.name == 'Newsletter'}
        newsletter_klass = concern.klass
        unless concern.klass
          concern.update!(klass: self.create_newsletter_klass(feature))
        end
        newsletter_klass = concern.klass

        concern = feature.concerns.detect {|c| c.name == 'Link'}
        link_klass = concern.klass
        unless concern.klass
          concern.update!(klass: self.create_link_klass(feature))
        end
        link_klass = concern.klass

        concern = feature.concerns.detect {|c| c.name == 'Visit'}
        visit_klass = concern.klass
        unless concern.klass
          concern.update!(klass: self.create_visit_klass(feature))
        end
        visit_klass = concern.klass

        concern = feature.concerns.detect {|c| c.name == 'NewsletterDelivery'}
        delivery_klass = concern.klass
        unless concern.klass
          concern.update!(klass: self.create_delivery_klass(feature))
        end
        delivery_klass = concern.klass

        option = feature.options.detect {|o| o.name == 'theme_klass'}
        theme_klass = option.value
        unless option.value
          option.update!(value: self.create_theme_klass(feature))
        end
        theme_klass = option.value

        recipient_info_feature = feature.schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
        recipient_klass = recipient_info_feature.concerns.detect {|c| c.name == 'RecipientEmailAddress'}&.klass

        self.create_newsletter_attributes(newsletter_klass)
        self.create_newsletter_associations(newsletter_klass, link_klass)

        self.create_delivery_attributes(delivery_klass)
        self.create_delivery_associations(delivery_klass, newsletter_klass, recipient_klass)

        self.create_link_attributes(link_klass)
        self.create_link_associations(newsletter_klass, link_klass, visit_klass)

        self.create_recipient_associations(newsletter_klass, recipient_klass, visit_klass)

        self.create_visit_attributes(visit_klass)
        self.create_visit_associations(link_klass, recipient_klass, visit_klass)

        self.create_theme_attributes(feature, theme_klass)
        self.create_theme_associations(feature, theme_klass)
      end

      def self.create_newsletter_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Newsletter',
          human_name_en: 'Newsletter',
          plural_human_name_fr: 'Newsletters',
          plural_human_name_en: 'Newsletters',
          table_profile: :medium,
          icon: 'mail-bulk',
        ).find_or_create_by!(name: 'Newsletter')
      end

      def self.create_newsletter_attributes(newsletter_klass)
        attrs_newsletter = []
        attrs_newsletter << {
          name: 'name',
          human_name_fr: 'Nom',
          human_name_en: 'Name',
          type: 'String',
        } unless newsletter_klass.attrs.where(name: 'name').exists?
        attrs_newsletter << {
          name: 'opening',
          human_name_fr: 'Ouvertures',
          human_name_en: 'Openings',
          type: 'Integer',
          formula: 'nth(select(links.click; links.category = "opening"); 0)',
        } unless newsletter_klass.attrs.where(name: 'opening').exists?
        attrs_newsletter << {
          name: 'unique_opening',
          human_name_fr: 'Ouverture unique',
          human_name_en: 'Unique Opening',
          type: 'Integer',
          formula: 'nth(select(links.unique_click; links.category = "opening"); 0)',
        } unless newsletter_klass.attrs.where(name: 'unique_opening').exists?
        attrs_newsletter << {
          name: 'unique_opening_percentage',
          human_name_fr: 'Pourcentage d\'ouverture unique',
          human_name_en: 'Unique opening percentage',
          type: 'Float',
          formula: 'nth(select(links.unique_click_percentage; links.category = "opening"); 0)',
        } unless newsletter_klass.attrs.where(name: 'unique_opening_percentage').exists?
        attrs_newsletter << {
          name: 'unsubscribe',
          human_name_fr: 'Désabonnement',
          human_name_en: 'Unsubscribe',
          type: 'Integer',
          formula: 'nth(select(links.click; links.category = "unsubscribe"); 0)',
        } unless newsletter_klass.attrs.where(name: 'unsubscribe').exists?
        attrs_newsletter << {
          name: 'unsubscribed_percentage',
          human_name_fr: 'Pourcentage de désabonnement',
          human_name_en: 'Unsubscribe percentage',
          type: 'Float',
          formula: 'nth(select(links.unique_click_percentage; links.category = "unsubscribe"); 0)',
        } unless newsletter_klass.attrs.where(name: 'unsubscribed_percentage').exists?
        attrs_newsletter << {
          name: 'npai',
          human_name_fr: 'Nombre de NPAI',
          human_name_en: 'NPAI count',
          type: 'Integer',
        } unless newsletter_klass.attrs.where(name: 'npai').exists?
        attrs_newsletter << {
          name: 'npai_percentage',
          human_name_fr: 'Taux NPAI',
          human_name_en: 'NPAI rate',
          type: 'Float',
        } unless newsletter_klass.attrs.where(name: 'npai_percentage').exists?
        attrs_newsletter << {
          name: 'preview',
          human_name_fr: 'Aperçu',
          human_name_en: 'Preview',
          type: 'String',
        } unless newsletter_klass.attrs.where(name: 'preview').exists?
        attrs_newsletter << {
          name: 'weight',
          human_name_fr: 'Poids',
          human_name_en: 'Weight',
          type: 'Integer',
        } unless newsletter_klass.attrs.where(name: 'weight').exists?
        attrs_newsletter << {
          name: 'num_recipients',
          human_name_fr: 'Nombre de destinataires',
          human_name_en: 'Number of Recipients',
          type: 'Integer',
        } unless newsletter_klass.attrs.where(name: 'num_recipients').exists?
        newsletter_klass.attrs.create!(attrs_newsletter) unless attrs_newsletter.empty?
      end

      def self.create_newsletter_associations(newsletter_klass, link_klass)
        unless newsletter_klass.associations.where(name: 'links').exists?
          newsletter_klass.associations.create_with(
            human_name_fr: 'Liens',
            human_name_en: 'Links'
          ).find_or_create_by!(name: 'links', type: 'HasMany', target_klass: link_klass)
        end
      end

      def self.create_link_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Lien newsletter',
          human_name_en: 'Newsletter link',
          plural_human_name_fr: 'Liens newsletter',
          plural_human_name_en: 'Newsletter links',
          table_profile: :medium,
          icon: 'link',
        ).find_or_create_by!(name: 'NewsletterLink')
      end

      def self.create_link_attributes(link_klass)
        attrs_link = []
        attrs_link << {
          name: 'url',
          human_name_fr: 'url',
          human_name_en: 'url',
          type: 'String',
        } unless link_klass.attrs.where(name: 'url').exists?
        attrs_link << {
          name: 'text',
          human_name_fr: 'Texte',
          human_name_en: 'Text',
          type: 'Text',
        } unless link_klass.attrs.where(name: 'text').exists?
        attrs_link << {
          name: 'click',
          human_name_fr: 'Clic',
          human_name_en: 'Click',
          type: 'Integer',
        } unless link_klass.attrs.where(name: 'click').exists?
        attrs_link << {
          name: 'unique_click',
          human_name_fr: 'Clic Unique',
          human_name_en: 'Unique Click',
          type: 'Integer',
        } unless link_klass.attrs.where(name: 'unique_click').exists?
        attrs_link << {
          name: 'unique_click_percentage',
          human_name_fr: 'Pourcentage de clic unique',
          human_name_en: 'Unique click percentage',
          type: 'Float',
          formula: 'min(round(unique_click * 100.0 / newsletter.num_recipients; 2); 100.0)',
        } unless link_klass.attrs.where(name: 'unique_click_percentage').exists?
        attrs_link << {
          name: 'unique_click_percentage_by_opening',
          human_name_fr: 'Pourcentage de clic unique par ouverture',
          human_name_en: 'Unique click percentage by opening',
          type: 'Float',
          formula: 'if(category = "opening"; unique_click_percentage; min(round(unique_click * 100.0 / newsletter.unique_opening; 2); 100.0))',
        } unless link_klass.attrs.where(name: 'unique_click_percentage_by_opening').exists?
        attrs_link << {
          name: 'category',
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
          ],
        } unless link_klass.attrs.where(name: 'category').exists?
        link_klass.attrs.create!(attrs_link) unless attrs_link.empty?
      end

      def self.create_link_associations(newsletter_klass, link_klass, visit_klass)
        links_association = newsletter_klass.associations.where(name: 'links').first
        links_association_attr = {
          name: 'newsletter',
          target_klass: newsletter_klass,
          inverse_of: links_association,
          type: 'BelongsTo',
          human_name: 'Newsletter',
        }
        link_klass.associations.create!(links_association_attr) unless link_klass.associations.where(name: 'newsletter').exists?

        newsletter_association = link_klass.associations.where(name: 'newsletter').first
        links_association.update!(inverse_of: newsletter_association)

        unless link_klass.associations.where(name:'visits').exists?
          link_klass.associations.create_with(
            human_name_fr: 'Visites',
            human_name_en: 'Visits'
          ).find_or_create_by!(name:'visits', type: 'HasMany', target_klass: visit_klass)
        end

      end

      def self.create_recipient_associations(newsletter_klass, recipient_klass, visit_klass)
        visits_association_attr = {
          name: 'visits',
          target_klass: visit_klass,
          type: "HasMany",
          human_name: "Visites",
        }
        recipient_klass.associations.create!(visits_association_attr) unless recipient_klass.associations.where(name: 'visits').exists?
      end

      def self.create_visit_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Visite newsletter',
          human_name_en: 'Newsletter visit',
          plural_human_name_fr: 'Visites newsletter',
          plural_human_name_en: 'Newsletter visits',
          table_profile: :medium,
          icon: 'blind',
        ).find_or_create_by!(name: 'NewsletterVisit')
      end

      def self.create_theme_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Theme newsletter',
          human_name_en: 'Newsletter Theme',
          plural_human_name_fr: 'Themes newsletter',
          plural_human_name_en: 'Newsletter themes',
          table_profile: :medium,
          icon: 'tags',
        ).find_or_create_by!(name: 'NewsletterTheme')
      end

      def self.create_visit_attributes(visit_klass)
        attrs_visit = []
        attrs_visit << {
          name: 'date',
          human_name_fr: 'Date',
          human_name_en: 'Date',
          type: 'DateTime',
        } unless visit_klass.attrs.where(name: 'date').exists?
        visit_klass.attrs.create!(attrs_visit) unless attrs_visit.empty?
      end

      def self.create_visit_associations(link_klass, recipient_klass, visit_klass)
        visit_link_association = link_klass.associations.where(name: 'visits').first

        link_association_attr = {
          name: 'link',
          target_klass: link_klass,
          inverse_of: visit_link_association,
          type: "BelongsTo",
          human_name: "Lien",
        }

        link_association = visit_klass.associations.create!(link_association_attr) unless visit_klass.associations.where(name: 'link').exists?

        visit_link_association.update!(inverse_of: link_association) unless link_association.nil?

        visit_recipient_association = recipient_klass.associations.where(name: 'visits').first

        recipient_association_attr = {
          name: 'recipient',
          target_klass: recipient_klass,
          inverse_of: visit_recipient_association,
          type: "BelongsTo",
          human_name: "Destinataire",
        }

        recipient_association = visit_klass.associations.create!(recipient_association_attr) unless visit_klass.associations.where(name: 'recipient').exists?

        visit_recipient_association.update!(inverse_of: recipient_association) unless recipient_association.nil?
      end

      def self.create_delivery_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Livraison newsletter',
          human_name_en: 'Newsletter delivery',
          plural_human_name_fr: 'Livraisons newsletter',
          plural_human_name_en: 'Newsletter deliveries',
          table_profile: :medium,
          icon: 'mail-bulk',
        ).find_or_create_by!(name: 'NewsletterDelivery')
      end

      def self.create_delivery_attributes(delivery_klass)
        attrs_delivery = []
        attrs_delivery << {
          name: 'delivery_date',
          human_name_fr: 'Date',
          human_name_en: 'Date',
          type: 'DateTime',
        } unless delivery_klass.attrs.where(name: 'delivery_date').exists?

        attrs_delivery << {
          name: 'sent',
          human_name_fr: 'Envoyé',
          human_name_en: 'Sent',
          type: 'Boolean',
        } unless delivery_klass.attrs.where(name: 'sent').exists?

        delivery_klass.attrs.create!(attrs_delivery) unless attrs_delivery.empty?
      end

      def self.create_delivery_associations(delivery_klass, newsletter_klass, recipient_klass)
        newsletter_delivery_assoc = newsletter_klass.associations.create_with(
          human_name_fr: 'Livraisons',
          human_name_en: 'Deliveries'
        ).find_or_create_by!(name: 'deliveries', type: 'HasMany', target_klass: delivery_klass)

        delivery_newsletter_assoc = delivery_klass.associations.create_with(
          human_name_fr: 'Newsletter',
          human_name_en: 'Newsletter',
          inverse_of: newsletter_delivery_assoc
        ).find_or_create_by!(name: 'newsletter', type: 'BelongsTo', target_klass: newsletter_klass)

        newsletter_delivery_assoc.update!(inverse_of: delivery_newsletter_assoc)

        recipient_delivery_assoc = recipient_klass.associations.create_with(
          human_name_fr: 'Livraisons de newsletter',
          human_name_en: 'Newsletter deliveries'
        ).find_or_create_by!(name: 'newsletter_deliveries', type: 'HasMany', target_klass: delivery_klass)

        delivery_recipient_assoc = delivery_klass.associations.create_with(
          human_name_fr: 'Destinataire',
          human_name_en: 'Recipient',
          inverse_of: recipient_delivery_assoc
        ).find_or_create_by!(name: 'recipient', type: 'BelongsTo', target_klass: recipient_klass)

        recipient_delivery_assoc.update!(inverse_of: delivery_recipient_assoc)
      end

      def self.create_theme_attributes(feature, theme_klass)
        attrs_theme = []
        attrs_theme << {
          name: 'name',
          human_name_fr: 'Intitulé',
          human_name_en: 'Label',
          type: 'String',
        } unless theme_klass.attrs.where(name: 'name').exists?
        theme_klass.attrs.create!(attrs_theme) unless attrs_theme.empty?
      end

      def self.create_theme_associations(feature, theme_klass)
        theme_associations_klasses = feature.options.detect {|o| o.name == 'theme_associations_klasses'}&.value
        theme_associations_klasses&.each do |k|
          theme_association_attr = {
            name: 'newsletter_themes',
            target_klass: theme_klass,
            type: "HasMany",
            human_name_fr: 'Thèmes de newsletter',
            human_name_en: 'Newsletter themes',
          }
          k.associations.create!(theme_association_attr) unless k.associations.where(name: 'newsletter_themes').exists?
        end
      end

      def self.load(schema)
        recipient_path = ::Dynamic::Knewsletter::RecipientPath.mount(schema)

        if schema.feature_enabled?('Dynamic::Knewsletter::Feature')
          feature = schema.features.detect{|e| e.name == self.name}
          Dynamic::Elasticsearch::Feature.include_opensearch_model(recipient_path, feature)
        end
        return true
      end

      def self.remove_large_associations_from_edit_in_place_forms(newsletter_klass, link_klass, visit_klass)
        edit_form = Dynamic::Form.where(klass_name: newsletter_klass.const_absolute_name, default: true).with_action([:edit_in_place]).first
        if edit_form
          elem = edit_form.elements.detect {|e| e.attribute_name == 'recipients'}
        end
        edit_form = Dynamic::Form.where(klass_name: link_klass.const_absolute_name, default: true).with_action([:edit_in_place]).first
        if edit_form
          elem = edit_form.elements.detect {|e| e.attribute_name == 'visits'}
        end
      end

    end

  end
end
