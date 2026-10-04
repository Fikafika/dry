module Dynamic
  module RecipientInfo
    module Feature; extend Dynamic::Feature

      DEPENDENCIES = [
        'Dynamic::Communication::Feature',
      ].freeze

      REVERSE_DEPENDENCIES = [
        'Dynamic::MailHosting::Feature',
        'Dynamic::Knewsletter::Feature',
      ].freeze

      def self.feature_attributes
        {
          human_name_fr: 'Informations de destinataires',
          human_name_en: "Recipient's informations",
          mandatory: false,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Base',
              human_name_fr: 'Informations du destinataire',
              human_name_en: "Recipient's informations",
            },
            {
              name: 'EmailAddress',
              human_name_fr: 'E-mail',
              human_name_en: 'E-mail',
              options_attributes: [
                {
                  name: 'recipient_association',
                  human_name_fr: "Association vers l'email unique",
                  human_name_en: 'Unique email association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: '',
                }
              ],
            },
            {
              name: 'PhoneNumber',
              human_name_fr: 'Téléphone',
              human_name_en: 'Phone',
              options_attributes: [
                {
                  name: 'recipient_association',
                  human_name_fr: 'Association vers le téléphone unique',
                  human_name_en: 'Unique phone association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: '',
                }
              ],
            },
            {
              name: 'Address',
              human_name_fr: 'Adresse',
              human_name_en: 'Address',
            },
            {
              name: 'RecipientEmailAddress',
              human_name_fr: 'E-mail unique',
              human_name_en: 'Unique e-mail',
            },
            {
              name: 'RecipientPhoneNumber',
              human_name_fr: 'Téléphone unique',
              human_name_en: 'Unique phone',
            },
          ],
        }
      end

      def self.after_enabled(feature)
        DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_or_create_by!(name: d)
          unless dependency.enabled?
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end
        self.create_klasses(feature)
      end

      def self.after_disabled(feature)
        REVERSE_DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          dependency&.update(enabled: false)
        end
      end

      def self.create_klasses(feature)
        recipient_info_klass = feature.schema.klasses.find_by(name: 'RecipientInfo') || self.create_recipient_info_klass(feature)
        feature.concerns.detect {|f| f.name == 'Base'}.update!(klass: recipient_info_klass)

        communication_feature = feature.schema.features.find_by_name('Dynamic::Communication::Feature')
        communication_klass = []
        communication_klass << communication_feature.concerns.detect {|c| c.name == 'Email'}.klass
        communication_klass << communication_feature.concerns.detect {|c| c.name == 'Phone'}.klass
        communication_klass << communication_feature.concerns.detect {|c| c.name == 'Address'}.klass

        concerns = []
        ['EmailAddress', 'PhoneNumber', 'Address'].each_with_index do |c_name, i|
          c = feature.concerns.detect {|k| k.name == c_name}
          unless c.klass
            c.update!(klass: communication_klass[i])
          end
          concerns << c
        end

        klasses = [recipient_info_klass]
        klasses << self.create_recipient_email_klass(feature, concerns[0].klass, recipient_info_klass)
        feature.concerns.detect {|k| k.name == 'RecipientEmailAddress'}.update!(klass: klasses[-1])
        klasses << self.create_recipient_phone_klass(feature, concerns[1].klass, recipient_info_klass)
        feature.concerns.detect {|k| k.name == 'RecipientPhoneNumber'}.update!(klass: klasses[-1])

        self.associate_with_address_klass(concerns[2].klass, recipient_info_klass)

        self.create_layouts_new(feature, klasses)
      end

      def self.create_recipient_info_klass(feature)
        raw_data = {
          name: 'RecipientInfo',
          human_name_fr: 'Information du destinataire',
          human_name_en: "Recipient's information",
          plural_human_name_fr: 'Informations des destinataires',
          plural_human_name_en: "Recipients' informations",
          icon: 'bullhorn',
          skip_create_default_forms: [:new],
          table_profile: :medium,
          attrs_attributes: [
            {
              name: 'global_consent',
              human_name_fr: 'Consentement global',
              human_name_en: 'Global consent',
              type: 'Boolean',
            },
            {
              name: 'npai',
              human_name_fr: 'NPAI',
              human_name_en: 'Return to sender',
              type: 'Boolean',
            },
            {
              name: 'pressure',
              human_name_fr: 'Pression éxercée',
              human_name_en: 'Pressure',
              type: 'Integer',
            },
            {
              name: 'source',
              human_name_fr: 'Source',
              human_name_en: 'Source',
              type: 'String',
            },
            {
              name: 'tracking_pixel_consent',
              human_name_fr: 'Consentement pixel de suivi',
              human_name_en: 'Tracking pixel consent',
              type: 'Boolean',
            },
          ]
        }

        return feature.schema.klasses.create!(raw_data)
      end

      def self.create_recipient_email_klass(feature, email_klass, recipient_klass)
        raw_data = {
          name: 'RecipientEmailAddress',
          name_attribute_id: '018e75cc-74be-74be-bbdd-4cd660b3ee95',
          frozen_table: true,
          human_name_fr: 'E-mail unique',
          human_name_en: 'Unique e-mail',
          plural_human_name_fr: 'E-mails uniques',
          plural_human_name_en: 'Unique e-mails',
          icon: 'envelope-square',
          skip_create_default_forms: [:new],
          table_profile: :small,
          attrs_attributes: [
            {
              id: '018e75cc-74be-74be-bbdd-4cd660b3ee95',
              name: 'address',
              human_name_fr: 'Adresse E-mail',
              human_name_en: 'E-mail Address',
              type: 'String',
            },
          ],
          validations_attributes: [
            {
              type: 'Format::Email',
              human_name_fr: 'Format e-mail',
              human_name_en: 'E-mail format',
              attr_id: '018e75cc-74be-74be-bbdd-4cd660b3ee95',
            },
            {
              type: 'Presence',
              human_name_fr: 'Présence',
              human_name_en: 'Presence',
              attr_id: '018e75cc-74be-74be-bbdd-4cd660b3ee95',
            },
            {
              type: 'Uniqueness',
              human_name_fr: 'E-mail unique',
              human_name_en: 'Unique e-mail',
              attr_ids: ['018e75cc-74be-74be-bbdd-4cd660b3ee95'],
            },
          ],
        }

        recipient_mail_klass = feature.schema.klasses.find_by(name: 'RecipientEmailAddress')
        recipient_mail_klass = feature.schema.klasses.create!(
          Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass)
        ) unless recipient_mail_klass

        recipient_assoc = recipient_mail_klass.associations.create_with(
          human_name_fr: 'Informations destinataire',
          human_name_en: "Recipient's informations",
          skip_create_default_forms: [:new],
        ).find_or_create_by!(
          name: 'info',
          type: 'BelongsTo',
          target_klass: recipient_klass,
        )
        unique_email_assoc = recipient_klass.associations.create_with(
          human_name_fr: 'Propriétaire',
          human_name_en: 'Owner',
          skip_create_default_forms: [:new],
        ).find_or_create_by!(
          name: 'target',
          type: 'BelongsTo',
        )
        recipient_assoc.update(inverse_of: unique_email_assoc)

        return recipient_mail_klass unless email_klass

        recipient_assoc = email_klass.associations.create_with(
          human_name_fr: 'E-mail unique',
          human_name_en: 'Unique e-mail',
          skip_create_default_forms: [:new],
        ).find_or_create_by!(
          name: 'recipient',
          type: 'BelongsTo',
          target_klass: recipient_mail_klass,
        )

        concern = feature.concerns.detect {|c| c.name == 'EmailAddress'}
        concern.options.detect {|o| o.name == 'recipient_association'}.update!(value: recipient_assoc)

        emails_assoc = recipient_mail_klass.associations.create_with(
          human_name_fr: 'E-mails',
          human_name_en: 'E-mails',
          skip_create_default_forms: [:new],
        ).find_or_create_by!(
          name: 'emails',
          type: 'HasMany',
          target_klass: email_klass,
          inverse_of: recipient_assoc,
        )
        recipient_assoc.update(inverse_of: emails_assoc)

        return recipient_mail_klass
      end

      def self.create_recipient_phone_klass(feature, phone_klass, recipient_klass)
        raw_data = {
          name: 'RecipientPhoneNumber',
          name_attribute_id: '018e75d5-4807-7080-b624-34148b92ad6b',
          human_name_fr: 'Téléphone unique',
          human_name_en: 'Unique phone',
          plural_human_name_fr: 'Téléphone uniques',
          plural_human_name_en: 'Unique phones',
          icon: 'phone-square',
          skip_create_default_forms: [:new],
          table_profile: :small,
          frozen_table: true,
          attrs_attributes: [
            {
              id: '018e75d5-4807-7080-b624-34148b92ad6b',
              human_name_fr: 'Numéro de Téléphone',
              human_name_en: 'Phone Number',
              type: 'String',
              name: 'number',
            }
          ],
          validations_attributes: [
            {
              attr_id: '018e75d5-4807-7080-b624-34148b92ad6b',
              type: 'Presence',
              name: 'presence',
              human_name_fr: 'Présence',
              human_name_en: 'Presence',
            },
            {
              attr_id: '018e75d5-4807-7080-b624-34148b92ad6b',
              type: 'Format::InternationalPhoneNumber',
              name: 'international_phone',
              human_name_fr: 'Téléphone International',
              human_name_en: 'International Phone',
            },
            {
              type: 'Uniqueness',
              human_name_fr: 'Téléphone unique',
              human_name_en: 'Unique phone',
              attr_ids: ['018e75d5-4807-7080-b624-34148b92ad6b'],
            },
          ]
        }

        recipient_phone_klass = feature.schema.klasses.find_by(name: 'RecipientPhoneNumber')
        recipient_phone_klass =  feature.schema.klasses.create!(
          Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass)
        ) unless recipient_phone_klass

        recipient_info_assoc = recipient_phone_klass.associations.create_with(
          human_name_fr: 'Informations destinataire',
          human_name_en: "Recipient's informations",
          skip_create_default_forms: [:new],
          inverse_of: recipient_klass.associations.detect {|a| a.name == 'target'}
        ).find_or_create_by!(
          name: 'info',
          type: 'BelongsTo',
          target_klass: recipient_klass,
        )

        return recipient_phone_klass unless phone_klass
        recipient_assoc = phone_klass.associations.create_with(
          human_name_fr: 'Numéro unique',
          human_name_en: 'Unique number',
          skip_create_default_forms: [:new],
        ).find_or_create_by!(
          name: 'recipient',
          type: 'BelongsTo',
          target_klass: recipient_phone_klass,
        )

        concern = feature.concerns.detect {|c| c.name == 'PhoneNumber'}
        concern.options.detect {|o| o.name == 'recipient_association'}.update!(value: recipient_assoc)

        phones_assoc = recipient_phone_klass.associations.create_with(
          human_name_fr: 'Téléphones',
          human_name_en: 'Phones',
          skip_create_default_forms: [:new],
        ).find_or_create_by!(
          name: 'phones',
          type: 'HasMany',
          target_klass: phone_klass,
          inverse_of: recipient_assoc,
        )
        recipient_assoc.update(inverse_of: phones_assoc)

        return recipient_phone_klass
      end

      def self.associate_with_address_klass(address_klass, recipient_klass)
        return unless address_klass

        address_klass.associations.create_with(
          human_name_fr: 'Information destinataire',
          human_name_en: "Recipient's info",
          skip_create_default_forms: [:new],
          inverse_of: recipient_klass.associations.detect {|a| a.name == 'target'},
        ).find_or_create_by!(
          name: 'info',
          type: 'BelongsTo',
          target_klass: recipient_klass,
        )
      end

      def self.create_layouts_new(feature, klasses)
        klasses.each do |k|
          next if feature.schema.layouts.find_by(klass_name: k.const_absolute_name, actions: 1)
          feature.schema.layouts.create!(
            human_name_fr: 'Nouveau',
            human_name_en: 'New',
            actions: [:new],
            klass_name: k.const_absolute_name,
            default: true,
            updated_when_schema_is_changed: false,
            elements_attributes: [{
              component: 'Layout::Container',
              children_attributes: [{
                component: 'Layout::Row',
                children_attributes: [{
                  component: 'Layout::Column',
                  component_params: {
                    class: 'p-0',
                  },
                  children_attributes: [{
                    component: 'Crm::Sheet::Toolbar',
                    component_params_converter_type: 'Crm::Sheet::Toolbar::ParamsConverter',
                  }],
                }],
              }],
            }],
          )
        end
      end

      def self.load(schema)
        communication_feature = schema.features.detect{|e| e.name == "Dynamic::Communication::Feature"}

        ::Dynamic::RecipientInfo.send(:define_singleton_method, "communication_feature") do
          return communication_feature
        end
      end

    end

    module RecipientEmailAddress
    end

    module RecipientPhoneNumber
    end
  end
end
