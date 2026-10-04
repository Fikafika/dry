module Dynamic
  module Amount
    module Feature; extend Dynamic::Feature

      DEPENDENCIES = [
        'Dynamic::Currency::Feature',
      ].freeze

      REVERSE_DEPENDENCIES = [
        'Dynamic::Transaction::Feature',
      ].freeze

      def self.feature_attributes
        {
          human_name_fr: 'Montant',
          human_name_en: 'Amount',
          mandatory: false,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Amount',
              human_name_fr: 'Montant',
              human_name_en: 'Amount',
            }
          ],
          concern_templates_attributes: [
            {
              name: 'VatComputable',
              human_name_fr: 'TVA Calculable',
              human_name_en: 'Computable VAT',
              options_attributes: [
                {
                  name: 'base_amount_attribute',
                  human_name_fr: 'Attribut vers le montant de base',
                  human_name_en: 'Base amount attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: '',
                },
                {
                  name: 'vat_rate_association',
                  human_name_fr: 'Association vers le taux de TVA',
                  human_name_en: 'VAT rate association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: '',
                },
                {
                  name: 'amount_excluding_vat_attribute',
                  human_name_fr: 'Attirbut du total HT',
                  human_name_en: 'Amount excluding VAT attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: '',
                },
                {
                  name: 'amount_including_vat_attribute',
                  human_name_fr: 'Attribut du total TTC',
                  human_name_en: 'Amount including VAT attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: '',
                },
                {
                  name: 'vat_amount_attribute',
                  human_name_fr: 'Attribut du total TVA',
                  human_name_en: 'VAT amount attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: '',
                },
                {
                  name: 'quantity_attribute',
                  human_name_fr: 'Attribute de la quantité',
                  human_name_en: 'Quantity attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: '',
                }
              ],
            }
          ],
          options_attributes: [
            {
              name: 'default_currency_iso_code',
              human_name_fr: 'Code iso de la devise par défaut',
              human_name_en: 'Default currency iso code',
              type: 'String',
              value: 'EUR'
            },
          ],
        }
      end

      def self.after_disabled(feature)
        REVERSE_DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          dependency.update(enabled: false)
        end
      end

      def self.after_enabled(feature)
        schema = feature.schema

        DEPENDENCIES.each do |d|
          dependency = schema.features.find_or_create_by!(name: d)
          unless dependency.enabled
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end

        amount = schema.klasses.find_by(name: 'Amount') || self.create_klasses(feature).first
        feature.concerns.detect {|c| c.name == 'Amount'}.update!(klass: amount)
        currency = schema.klasses.find_by(name: 'Currency')
        self.create_currency_association(currency, amount)
      end

      def self.after_enabled_and_commit_schema(feature)
        amount_klass = feature.schema.klasses.find_by(name: 'Amount')
        unless amount_klass.name_attribute_id
          amount_klass.update!(name_attribute_id: amount_klass.attrs.detect {|a| a.name == 'name'}&.id)
        end

        default_currency = feature.options.detect {|o| o.name == 'default_currency_iso_code'}&.value
        return unless default_currency
        klass = feature.schema.klasses.detect {|k| k.name == 'Amount'}
        form = Dynamic::Form.includes(:elements).with_action([:input]).where(klass_name: klass.const_absolute_name, default: true).first
        elem = form.elements.detect {|e| e.attribute_name == 'currency'}
        currency_klass = feature.schema.klasses.detect {|k| k.name == 'Currency'}
        return unless elem && currency_klass
        elem.update!(editor: :hidden, default_value_record: currency_klass.const.find_by(iso_code: default_currency) )
      end

      def self.create_klasses(feature)
        default_currency = feature.options.detect {|o| o.name == 'default_currency_iso_code'}&.value
        icon = "#{default_currency == 'EUR' ? 'euro' : 'dollar'}-sign"
        raw_data =
        [
          {
            id: '018ebc37-cf05-70b7-b27c-16e3f8b7c496',
            name: 'Amount',
            human_name_fr: 'Montant',
            human_name_en: 'Amount',
            plural_human_name_fr: 'Montant',
            plural_human_name_en: 'Amounts',
            icon: icon,
            table_profile: :medium,
            update_menu_items: false,
            attrs_attributes: [
              {
                type: 'String',
                name: 'name',
                human_name_fr: 'Nom',
                human_name_en: 'Name',
              },
              {
                id: '018ebc37-cf05-70b7-b27c-16e3f8b7c497',
                type: 'Float',
                name: 'raw_value',
                human_name_fr: 'Valeur brute',
                human_name_en: 'Raw value',
                locked: true,
              },
              {
                id: '018ebc37-cf05-70b7-b27c-16e3f8b7c498',
                type: 'Float',
                name: 'percent',
                human_name_fr: 'Pourcentage',
                human_name_en: 'Percent',
                format: 'x100_percentage',
                format_options: {precision: 2},
                locked: true,
              },
              {
                type: 'DateTime',
                name: 'validity_start',
                human_name_fr: 'Date et heure de début de validité',
                human_name_en: 'Validity start datetime',
              },
              {
                type: 'DateTime',
                name: 'validity_end',
                human_name_fr: 'Date et heure de fin de validité',
                human_name_en: 'Validity end datetime',
              },
              {
                type: 'Enum',
                name: 'validity',
                human_name_fr: 'Validité',
                human_name_en: 'Validity',
                values_attributes: [
                  {
                    name: 'in_future',
                    human_name_fr: 'A venir',
                    human_name_en: 'In future',
                  },
                  {
                    name: 'ongoing',
                    human_name_fr: 'En cours',
                    human_name_en: 'Ongoing',
                  },
                  {
                    name: 'past',
                    human_name_fr: 'Passé',
                    human_name_en: 'Past',
                  },
                ],
              },
            ],
            validations_attributes: [
              {
                id: '018ebc37-cf05-70b7-b27c-16e3f8b7c499',
                name: 'value_or_percent',
                type: 'EitherPresence',
                attr_ids: ['018ebc37-cf05-70b7-b27c-16e3f8b7c497', '018ebc37-cf05-70b7-b27c-16e3f8b7c498'],
                human_name_fr: 'Valeur fixe ou pourcentage présent',
                human_name_en: 'Fixed value or percent present',
              },
            ]
          },
          {
            name: 'Vat',
            human_name_fr: 'Taux de TVA',
            human_name_en: 'VAT rate',
            plural_human_name_fr: 'Taux de TVA',
            plural_human_name_en: 'VAT rates',
            superklass_id: '018ebc37-cf05-70b7-b27c-16e3f8b7c496',
            icon: 'balance-scale',
            attrs_attributes: [
              {
                id: '018ebc37-cf05-70b7-b27c-16e3f8b7c477',
                name: 'code',
                type: 'Enum',
                human_name_fr: 'Code',
                human_name_en: 'Code',
                values_attributes: [
                  {name: 'S', human_name_fr: 'Standard', human_name_en: 'Standard'},
                  {name: 'E', human_name_fr: 'Exonéré', human_name_en: 'Exempt'},
                  {name: 'AE', human_name_fr: 'Autoliquidation', human_name_en: 'Reverse charge'},
                  {name: 'K', human_name_fr: 'Exonération pour cause de livraison intracommunautaire', human_name_en: 'Exempt due to intra-Community supply'},
                  {name: 'G', human_name_fr: "AutExonération pour cause d'export hors UE", human_name_en: 'Exempt due to export outside the EU'},
                  {name: 'O', human_name_fr: "Hors du périmètre d'application", human_name_en: 'Outside of scope'},
                  {name: 'Z', human_name_fr: 'Taux égal à 0', human_name_en: 'Rate equal to 0'},
                ]
              }
            ],
            validations_attributes: [
              {
                name: 'code_presence',
                type: 'Presence',
                attr_id: '018ebc37-cf05-70b7-b27c-16e3f8b7c477',
                human_name_fr: 'Présence du code',
                human_name_en: 'Code présence',
              },
            ]
          }
        ]
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_currency_association(currency, amount)
        amount.associations.create_with(
          human_name_fr: 'Devise',
          human_name_en: 'Currency',
        ).find_or_create_by(
          name: 'currency',
          type: 'BelongsTo',
          target_klass: currency,
        )
      end

    end
  end
end
