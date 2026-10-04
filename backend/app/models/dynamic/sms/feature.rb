module Dynamic
  module Sms
    module Feature; extend Dynamic::Feature

      ENUM_STATE = [
        {
          name: 'created',
          human_name_fr: 'Créé',
          human_name_en: 'Created',
        },
        {
          name: 'ordered',
          human_name_fr: 'Commandé',
          human_name_en: 'Ordered',
        },
        {
          name: 'error on sending',
          human_name_fr: %q[Erreur lors de l'envoi],
          human_name_en: 'Error on sending',
        },
        {
          name: 'delivered',
          human_name_fr: 'Délivré',
          human_name_en: 'Delivered',
        },
        {
          name: 'unsubscribed',
          human_name_fr: 'Désinscrit',
          human_name_en: 'Unsubscribed',
        },
        {
          name: 'blocked',
          human_name_fr: 'Bloqué',
          human_name_en: 'Blocked',
        },
        {
          name: 'rejected',
          human_name_fr: 'Rejeté',
          human_name_en: 'Rejected',
        },
        {
          name: 'hard_bounce',
          human_name_fr: 'Hard bounce',
          human_name_en: 'Hard bounce',
        },
        {
          name: 'soft_bounce',
          human_name_fr: 'Soft bounce',
          human_name_en: 'Soft bounce',
        },
        {
          name: 'replied',
          human_name_fr: 'Répondu',
          human_name_en: 'Replied',
        },
        {
          name: 'accepted',
          human_name_fr: 'Accepté',
          human_name_en: 'Accepted',
        },
        {
          name: 'sent',
          human_name_fr: 'Envoyé',
          human_name_en: 'Sent',
        },
      ]

      def self.feature_attributes
        {
          # no dependency
          human_name_fr: 'Sms',
          human_name_en: 'Sms',
          mandatory: false,
          enabled: false,
          options_attributes: [
            {
              name: 'phone_klass',
              human_name_fr: 'Table correspondant au téléphone',
              human_name_en: 'Phone table',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: ''
            },
            {
              name: 'phone_number_attribute',
              human_name_fr: 'Attribut correspondant au numéro de téléphone',
              human_name_en: 'Attribute corresponding to phone number',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: ''
            },
            {
              name: 'owner_association',
              human_name_fr: 'Association correspondant au propriétaire de téléphone',
              human_name_en: 'Attribute corresponding to phone owner',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              value: ''
            },
            {
              name: 'default_sender',
              human_name_fr: 'Expéditeur par défaut',
              human_name_en: 'Default sender',
              type: 'String',
              value: nil
            },
            {
              name: 'phone_number_formula',
              human_name_fr: 'Formule du numéro de téléphone',
              human_name_en: "Phone's number formula",
              type: 'String',
              value: ''
            },
            {
              name: 'owner_formula',
              human_name_fr: 'Formule du propriétaire téléphone',
              human_name_en: "Phone's owner formula",
              type: 'String',
              value: ''
            },
          ],
          concerns_attributes: [
            {
              name: 'Sms',
              human_name_fr: 'Sms',
              human_name_en: 'Sms',
              options_attributes: [
                {
                  name: 'phone_number_attribute',
                  human_name_fr: 'Attribut du numéro de téléphone',
                  human_name_en: 'Attribute for phone number',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'phone_association',
                  human_name_fr: 'Association vers Téléphone',
                  human_name_en: 'Association through Phone',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'owner_association',
                  human_name_fr: 'Association vers Propriétaire',
                  human_name_en: 'Association through Owner',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'History',
              human_name_fr: 'Historiques',
              human_name_en: 'Histories'
            },
          ],
          concern_templates_attributes: [
            {
              name: 'Owner',
              human_name_fr: 'Propriétaire',
              human_name_en: 'Owner',
              template: true,
              options_attributes: [
                {
                  name: 'default_sender',
                  human_name_fr: 'Expéditeur par défaut',
                  human_name_en: 'Default sender',
                  type: 'String',
                  value: nil
                },
                {
                  name: 'phone_formula',
                  human_name_fr: "Formule des téléphones pour l'envoi multiple",
                  human_name_en: 'Phones formula for multiple sending',
                  type: 'String',
                  value: nil
                },
                {
                  name: 'phone_number_formula',
                  human_name_fr: "Formule des numéros de téléphones pour l'envoi multiple",
                  human_name_en: "Phones' number formula for multiple sending",
                  type: 'String',
                  value: nil
                },
                {
                  name: 'owner_formula',
                  human_name_fr: "Formule des propriétaires pour l'envoi multiple",
                  human_name_en: "Phone's owner formula for multiple sending",
                  type: 'String',
                  value: ''
                },
              ]
            },
          ]
        }
      end

      def self.after_enabled(feature)
        phone_klass = feature.options.detect {|o| o.name == 'phone_klass'}&.value

        unless phone_klass
          feature.errors.add(:options, :missing)
          raise ActiveRecord::RecordInvalid.new(feature)
        end

        phone_klass_name = phone_klass.const_absolute_name

        sms_klass = feature.schema.klasses.find_by(name: 'Sms') || create_sms_klass(feature, phone_klass_name)
        history_klass = feature.schema.klasses.find_by(name: 'SmsHistory') || create_history_klass(feature)

        create_associations(feature, sms_klass, history_klass, phone_klass)

        sms_concern = feature.concerns.detect {|f| f.name == 'Sms'}
        sms_concern.options.detect {|o| o.name == 'owner_association'}&.update(value: sms_klass.associations.detect {|a| a.name == 'owners'})
        sms_concern.options.detect {|o| o.name == 'phone_association'}&.update(value: sms_klass.associations.detect {|a| a.name == 'phones'})
        sms_concern.options.detect {|o| o.name == 'phone_number_attibute'}&.update(value: sms_klass.attrs.detect {|a| a.name == 'phone_number'})
        sms_concern.update(klass: sms_klass)
        feature.concerns.detect {|f| f.name == 'History'}.update(klass: history_klass)

        feature.schema.touch # Use as a way load D::My::Sms for forms creation
        self.create_sms_forms(feature, sms_klass, phone_klass_name)
      end

      def self.create_sms_klass(feature, phone_klass)
        raw_data = {
          name: 'Sms',
          name_attribute_id: '018e7607-bfef-79d0-b3a8-8a5667e39257',
          human_name_fr: 'Sms',
          human_name_en: 'Sms',
          plural_human_name_fr: 'Sms',
          plural_human_name_en: 'Sms',
          icon: 'sms',
          skip_create_default_forms: true,
          table_profile: :small,
          attrs_attributes: [
            {
              id: '018e7b08-e0bd-7b9b-bdf6-a9640c98bac3',
              name: 'sender',
              human_name_fr: 'Expéditeur',
              human_name_en: 'Sender',
              type: 'String',
            },
            {
              id: '018e7607-bfef-79d0-b3a8-8a5667e39257',
              name: 'phone_number',
              human_name_fr: 'Numéro de téléphone',
              human_name_en: 'Phone number',
              type: 'String',
            },
            {
              id: '018e7b08-8a87-7190-84a6-c78b945a88d0',
              name: 'message',
              human_name_fr: 'Contenu',
              human_name_en: 'Message',
              type: 'Text',
            },
            {
              name: 'state',
              human_name_fr: 'Statut',
              human_name_en: 'State',
              type: 'Enum',
              values_attributes: ENUM_STATE
            },
          ],
          validations_attributes: [
            {
              name: 'message_presence',
              type: 'Presence',
              attr_id: '018e7b08-8a87-7190-84a6-c78b945a88d0',
              human_name_fr: 'Présence Contenu',
              human_name_en: 'Message Presence',
            },
            {
              name: 'phone',
              type: 'Format::PhoneNumber',
              attr_id: '018e7607-bfef-79d0-b3a8-8a5667e39257',
              human_name_fr: 'Téléphone',
              human_name_en: 'Phone',
            },
            {
              name: 'phone_presence',
              type: 'Presence',
              attr_id: '018e7607-bfef-79d0-b3a8-8a5667e39257',
              human_name_fr: 'Présence Téléphone',
              human_name_en: 'Phone Presence',
            },
            {
              name: 'sender_format',
              type: "Format::Base",
              attr_id: '018e7b08-e0bd-7b9b-bdf6-a9640c98bac3',
              expression: '\\A([a-zA-Z0-9]{2,11})\\z',
              human_name_fr: %q[Format de l'expéditeur],
              human_name_en: 'Sender Format',
            },
            {
              name: 'sender_presence',
              attr_id: '018e7b08-e0bd-7b9b-bdf6-a9640c98bac3',
              human_name_fr: 'Présence Expéditeur',
              human_name_en: 'Sender Presence',
              type: 'Presence',
            }
          ]
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass)
        feature.schema.klasses.create!(attrs)
      end

      def self.create_history_klass(feature)
        raw_data = {
          name: 'SmsHistory',
          human_name_fr: 'SMS Historique',
          human_name_en: 'SMS History',
          plural_human_name_fr: 'SMS Historiques',
          plural_human_name_en: 'SMS Histories',
          icon: 'history',
          skip_create_default_forms: [:new],
          table_profile: :small,
          attrs_attributes: [
            {
              name: 'state',
              human_name_fr: 'Statut',
              human_name_en: 'State',
              type: 'Enum',
              values_attributes: ENUM_STATE,
            },
            {
              name: 'event_date',
              human_name_fr: %q[Date d'évènement],
              human_name_en: 'Event date',
              type: 'DateTime',
            },
            {
              name: 'event_description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
              type: 'String',
            }
          ]
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass)
        feature.schema.klasses.create!(attrs)
      end

      def self.create_sms_forms(feature, sms, phone_klass_name)
        attrs_by_name = sms.attrs.index_by(&:name).merge(sms.associations.index_by(&:name))
        sms_klass_name = sms.const_absolute_name
        target_klasses_for_owner = self.owners_concern(feature).map {|k| k.klass&.const_absolute_name}.compact
        default_sender = feature.options.detect {|o| o.name == 'default_sender'}&.value
        phone_number_formula = feature.options.detect {|o| o.name == 'phone_number_formula'}&.value
        owner_formula = feature.options.detect {|o| o.name == 'owner_formula'}&.value
        forms = [
          {
            human_name_fr: 'Nouveau Sms',
            human_name_en: 'New Sms',
            actions: [:new],
            default: true,
            updated_when_schema_is_changed: false,
            mode: :input,
            klass_name: sms_klass_name,
            elements_attributes: [
              {
                root_klass_name: sms_klass_name,
                klass_name: sms_klass_name,
                attribute_name: 'owners',
                type: 'Association::HasMany',
                requirement: 'mandatory',
                max: 1,
              },
              {
                root_klass_name: sms_klass_name,
                klass_name: sms_klass_name,
                attribute_name: 'phones',
                type: 'Association::HasMany',
                requirement: 'mandatory',
                autocomplete_filters: {owner: {contains_id: {variable: 'owners'}}},
                max: 1,
              },
              sms.dynamic_form_element_attrs(attrs_by_name['sender']).merge(
                requirement: 'mandatory',
                default_value: default_sender
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['message']).merge(
                requirement: 'mandatory',
                editor: 'smsarea',
              ),
            ],
          },
          {
            human_name_fr: 'Vignette',
            human_name_en: 'List item',
            actions: [:show],
            mode: :read_only,
            default: true,
            updated_when_schema_is_changed: false,
            klass_name: sms_klass_name,
            elements_attributes: [
              {
                root_klass_name: sms_klass_name,
                klass_name: sms_klass_name,
                attribute_name: 'phones',
                type: 'Association::HasMany',
              },
              sms.dynamic_form_element_attrs(attrs_by_name['sender']),
              sms.dynamic_form_element_attrs(attrs_by_name['message']),
              sms.dynamic_form_element_attrs(attrs_by_name['state']),
            ],
          },
          {
            human_name_fr: 'Edition direct',
            human_name_en: 'Edit in place',
            actions: [:edit],
            mode: :edit_in_place,
            default: true,
            updated_when_schema_is_changed: false,
            klass_name: sms_klass_name,
            elements_attributes: [
              {
                root_klass_name: sms_klass_name,
                klass_name: sms_klass_name,
                attribute_name: 'owners',
                type: 'Association::HasMany',
                disabled: true,
              },
              {
                root_klass_name: sms_klass_name,
                klass_name: sms_klass_name,
                attribute_name: 'phones',
                type: 'Association::HasMany',
                disabled: true,
              },
              sms.dynamic_form_element_attrs(attrs_by_name['sender']).merge(
                disabled: true,
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['message']).merge(
                disabled: true,
                editor: 'smsarea'
              ),
            ],
          },
          {
            human_name_fr: 'Nouveau Sms',
            human_name_en: 'New Sms',
            actions: [:new],
            default: true,
            updated_when_schema_is_changed: false,
            mode: :input,
            klass_name: sms_klass_name,
            target_klass_name: phone_klass_name,
            source_klass_name: sms_klass_name,
            association_klass_name: phone_klass_name,
            association_name: 'smses',
            elements_attributes: [
              sms.dynamic_form_element_attrs(attrs_by_name['sender']).merge(
                requirement: 'mandatory',
                default_value: default_sender
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['message']).merge(
                requirement: 'mandatory',
                editor: 'smsarea',
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['phone_number']).merge(
                default_value_formula: phone_number_formula,
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              ),
              {
                root_klass_name: sms_klass_name,
                klass_name: sms_klass_name,
                attribute_name: 'owners',
                type: 'Association::HasMany',
                default_value_formula: owner_formula,
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              },
            ],
          },
        ]
        forms.push(*self.owners_form(feature, sms, attrs_by_name))
        forms = forms.select do |f|
          !feature.schema.forms.with_actions(f[:actions]).where(
            klass_name: f[:klass_name],
            mode: f[:mode],
            target_klass_name: f[:target_klass_name],
            source_klass_name: f[:source_klass_name],
            association_klass_name: f[:association_klass_name],
            association_name: f[:association_name],
          ).exists?
        end
        feature.schema.forms.create!(forms) unless forms.empty?
      end

      def self.create_associations(feature, sms, history, phone_klass)
        history_owner = history.associations.create_with(
          human_name_fr: 'Concerne',
          human_name_en: 'Owner',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'message',
          type: 'BelongsTo',
          target_klass: sms,
        )
        sms_histories = sms.associations.create_with(
          human_name_fr: 'Historiques',
          human_name_en: 'Histories',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'histories',
          type: 'HasMany',
          target_klass: history,
          inverse_of: history_owner,
        )

        history_owner.update(inverse_of: sms_histories)

        belongs_to_sms = sms.associations.create_with(
          human_name_fr: 'Téléphone',
          human_name_en: 'Phone',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'phones',
          type: 'HasMany',
          target_klass: phone_klass,
        )
        has_many_phone = phone_klass.associations.create_with(
          human_name_fr: 'SMS',
          human_name_en: 'SMS',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'smses',
          type: 'HasMany',
          target_klass: sms,
          inverse_of: belongs_to_sms,
        )

        belongs_to_sms.update(inverse_of: has_many_phone)

        self.associate_owners(feature, sms)
      end

      private

      def self.owners_concern(feature)
        feature.concerns.select {|c| c.name == 'Owner'}
      end

      def self.owner_option_value(owner_concern, option_name)
        owner_concern.options.detect {|o| o.name == option_name}&.value
      end

      def self.owners_form(feature, sms, attrs_by_name)
        self.owners_concern(feature).map do |owner|
          next unless owner&.klass
          sender = self.owner_option_value(owner, 'default_sender')
          phone_formula = self.owner_option_value(owner, 'phone_formula')
          phone_number_formula = self.owner_option_value(owner, 'phone_number_formula')
          owner_formula = self.owner_option_value(owner, 'owner_formula')
          owner_klass_name = owner.klass.const_absolute_name
          [{
            human_name_fr: 'Nouveau Sms',
            human_name_en: 'New Sms',
            actions: [:new],
            default: true,
            updated_when_schema_is_changed: false,
            mode: :input,
            klass_name: sms.const_absolute_name,
            target_klass_name: owner_klass_name,
            source_klass_name: sms.const_absolute_name,
            association_klass_name: owner_klass_name,
            association_name: 'smses',
            elements_attributes: [
              {
                root_klass_name: sms.const_absolute_name,
                klass_name: sms.const_absolute_name,
                attribute_name: 'phones',
                type: 'Association::HasMany',
                requirement: 'mandatory',
                autocomplete_filters: {owner: {contains_id: {variable: 'owner'}}},
                errors_from: ['phones'],
                max: 1,
              },
              {
                root_klass_name: sms.const_absolute_name,
                klass_name: sms.const_absolute_name,
                attribute_name: 'owners',
                type: 'Association::HasMany',
                default_value_formula: owner_formula,
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              },
              sms.dynamic_form_element_attrs(attrs_by_name['sender']).merge(
                requirement: 'mandatory',
                default_value: sender,
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['message']).merge(
                requirement: 'mandatory',
                editor: 'smsarea',
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['phone_number']).merge(
                default_value_formula: phone_number_formula,
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              ),
            ],
          },
          {
            human_name_fr: 'Envoi Multiple Sms',
            human_name_en: 'Sms Mass Send',
            actions: [:submit_all],
            default: true,
            updated_when_schema_is_changed: false,
            mode: :input,
            klass_name: sms.const_absolute_name,
            target_klass_name: owner_klass_name,
            source_klass_name: sms.const_absolute_name,
            association_klass_name: owner_klass_name,
            association_name: 'smses',
            elements_attributes: [
              sms.dynamic_form_element_attrs(attrs_by_name['sender']).merge(
                requirement: 'mandatory',
                default_value: sender,
              ),
              sms.dynamic_form_element_attrs(attrs_by_name['message']).merge(
                requirement: 'mandatory',
                editor: 'smsarea',
              ),
              {
                root_klass_name: sms.const_absolute_name,
                klass_name: sms.const_absolute_name,
                attribute_name: 'phones',
                type: 'Association::HasMany',
                default_value_formula: phone_formula,
                record_type_for_default_value_formula: :target_record,
                errors_from: ['phones'],
                editor: :hidden,
              },
              {
                root_klass_name: sms.const_absolute_name,
                klass_name: sms.const_absolute_name,
                attribute_name: 'owners',
                type: 'Association::HasMany',
                default_value_formula: owner_formula,
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              },
              sms.dynamic_form_element_attrs(attrs_by_name['phone_number']).merge(
                default_value_formula: phone_number_formula,
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              ),
            ],
          }]
        end.flatten
      end

      def self.associate_owners(feature, sms)
        sms.associations.create_with(
          human_name_fr: 'Propriétaire',
          human_name_en: 'Owner',
          skip_create_default_forms: true,
        ).find_or_create_by(
          name: 'owners',
          type: 'HasMany',
        )

        self.owners_concern(feature).each do |o|
          next unless o&.klass
          o.klass.associations.create_with(
            human_name_fr: 'SMS',
            human_name_en: 'SMS',
            skip_create_default_forms: true,
          ).find_or_create_by(
            name: 'smses',
            type: 'HasMany',
            target_klass: sms,
          )
        end
      end
    end
  end
end
