module Dynamic
  module Communication
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Communication',
          human_name_en: 'Communication',
          mandatory: false,
          visible: true,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Email',
              human_name_fr: 'Email',
              human_name_en: 'Email',
              options_attributes: [
                {
                  name: 'address_attribute',
                  human_name_fr: "Attribut de l'adresse email",
                  human_name_en: 'Email address attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'tag_attribute',
                  human_name_fr: "Attribut du tag de l'email",
                  human_name_en: 'Email tag attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'global_consent_attribute',
                  human_name_fr: 'Attribut du consentement email',
                  human_name_en: 'Email consent attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'tracking_pixel_consent_attribute',
                  human_name_fr: 'Attribut du consentement de pixel de suivi',
                  human_name_en: 'Tracking pixel consent attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'npai_attribute',
                  human_name_fr: 'Attribut du npai email',
                  human_name_en: 'Email npai attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'owner_association',
                  human_name_fr: "Association du propriétaire de l'email",
                  human_name_en: 'Email owner association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'contact_emails_association',
                  human_name_fr: "Association entre contact et emails",
                  human_name_en: 'Association between contact and emails',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'account_emails_association',
                  human_name_fr: "Association entre compte et emails",
                  human_name_en: 'Association between account and emails',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Phone',
              human_name_fr: 'Téléphone',
              human_name_en: 'Phone',
              options_attributes: [
                {
                  name: 'number_attribute',
                  human_name_fr: 'Attribut du numéro de téléphone',
                  human_name_en: 'Phone number attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'tag_attribute',
                  human_name_fr: 'Attribut du tag du téléphone',
                  human_name_en: 'Phone tag attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'owner_association',
                  human_name_fr: 'Association du propriétaire du téléphone',
                  human_name_en: 'Phone owner association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'contact_phones_association',
                  human_name_fr: "Association entre contact et téléphones",
                  human_name_en: 'Association between contact and phones',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'account_phones_association',
                  human_name_fr: "Association entre compte et téléphones",
                  human_name_en: 'Association between account and phones',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Address',
              human_name_fr: 'Adresse',
              human_name_en: 'Address',
              options_attributes: [
                {
                  name: 'tag_attribute',
                  human_name_fr: "Attribut du tag de l'adresse",
                  human_name_en: 'Address tag attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'street_attribute',
                  human_name_fr: "Attribut de la rue de l'adresse",
                  human_name_en: 'Address street attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'second_street_attribute',
                  human_name_fr: "Attribut du complément de l'adresse",
                  human_name_en: 'Address second street attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'third_street_attribute',
                  human_name_fr: "Attribut du complément 2 de l'adresse",
                  human_name_en: 'Address third street attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'city_attribute',
                  human_name_fr: "Attribut de la ville de l'adresse",
                  human_name_en: 'Address city attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'zip_code_attribute',
                  human_name_fr: "Attribut du code postal de l'adresse",
                  human_name_en: 'Address zip code attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'county_attribute',
                  human_name_fr: "Attribut du département de l'adresse",
                  human_name_en: 'Address county attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'state_attribute',
                  human_name_fr: "Attribut de la région de l'adresse",
                  human_name_en: 'Address state attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'country_attribute',
                  human_name_fr: "Attribut du pays de l'adresse",
                  human_name_en: 'Address country attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'latitude_attribute',
                  human_name_fr: "Attribut de la latitude de l'adresse",
                  human_name_en: 'Address latitude attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'longitude_attribute',
                  human_name_fr: "Attribut de la longitude de l'adresse",
                  human_name_en: 'Address longitude attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'delivery_mention_attribute',
                  human_name_fr: 'Attribut de la mention de livraison',
                  human_name_en: 'Delivery mention attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'second_delivery_mention_attribute',
                  human_name_fr: 'Attribut de la seconde mention de livraison',
                  human_name_en: 'Second delivery mention attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'name_attribute',
                  human_name_fr: "Attribut du nom de l'objet",
                  human_name_en: 'Object name attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'owner_association',
                  human_name_fr: "Association du propriétaire de l'adresse",
                  human_name_en: 'Address owner association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'contact_addresses_association',
                  human_name_fr: "Association entre contact et adresses",
                  human_name_en: 'Association between contact and addresses',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'account_addresses_association',
                  human_name_fr: "Association entre compte et adresses",
                  human_name_en: 'Association between account and addresses',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            }
          ],
          options_attributes: [
            {
              name: 'contact_klass',
              human_name_fr: 'Table des contact',
              human_name_en: 'Contact Table',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: nil
            },
            {
              name: 'account_klass',
              human_name_fr: 'Table des comptes',
              human_name_en: 'Account Table',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: nil
            },
            {
              name: 'elasticsearch_indices_already_created',
              human_name_en: 'Elasticsearch indices already created',
              human_name_fr: "Creation des index elasticsearch effectuée",
              type: 'Boolean',
              value: false
            },
          ],
        }
      end

      def self.after_enabled(feature)
        contact_schema_klass_option = feature.options.detect {|o| o.name == 'contact_klass'}
        unless contact_schema_klass_option.value
          contact_schema_klass_option.errors.add :value, :blank
          raise ActiveRecord::RecordInvalid.new(contact_schema_klass_option)
        end
        self.create_klasses(feature)
      end

      def self.after_enabled_and_commit_schema(feature)
        email_concern = feature.concerns.detect {|c| c.name == 'Email'}
        email_concern.klass.update!(name_attribute_id: email_concern.options.detect {|o| o.name == 'address_attribute'}.value_string)
        phone_concern = feature.concerns.detect {|c| c.name == 'Phone'}
        phone_concern.klass.update!(name_attribute_id: phone_concern.options.detect {|o| o.name == 'number_attribute'}.value_string)
        address_concern = feature.concerns.detect {|c| c.name == 'Address'}
        address_concern.klass.update!(name_attribute_id: address_concern.options.detect {|o| o.name == 'name_attribute'}.value_string)
      end

      def self.create_klasses(feature)
        email_concern = feature.concerns.detect {|c| c.name == 'Email'}
        unless email_concern.klass
          email_concern.update!(klass: self.create_email_klass(feature))
        end
        self.create_email_attributes(email_concern)
        self.create_email_validations(email_concern)
        self.create_email_associations(email_concern)
        self.update_options_for_indexed_json(email_concern.klass)
        self.update_global_search_fields(email_concern.klass)

        phone_concern = feature.concerns.detect {|c| c.name == 'Phone'}
        unless phone_concern.klass
          phone_concern.update!(klass: self.create_phone_klass(feature))
        end
        self.create_phone_attributes(phone_concern)
        self.create_phone_validations(phone_concern)
        self.create_phone_associations(phone_concern)

        address_concern = feature.concerns.detect {|c| c.name == 'Address'}
        unless address_concern.klass
          address_concern.update!(klass: self.create_address_klass(feature))
        end
        self.create_address_attributes(address_concern)
        self.create_address_associations(address_concern)

        self.create_email_contact(feature, email_concern.klass)
        self.create_phone_contact(feature, phone_concern.klass)
        self.create_address_contact(feature, address_concern.klass)
      end

      def self.create_email_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Email',
          human_name_en: 'Email',
          plural_human_name_fr: 'Emails',
          plural_human_name_en: 'Emails',
          icon: 'envelope',
          table_profile: :medium,
        ).find_or_create_by!(name: 'Email')
      end

      def self.update_options_for_indexed_json(email_klass)
        options = email_klass.options_for_indexed_json_deserialized.deep_dup
        ['address', 'tag'].each do |a|
          next if options['only']&.include?(a)
          options['only'] ||= []
          options['only'] << a
        end

        if !options.dig('include', 'owner')
          options['include'] ||= {}
          options['include']['owner'] = {only: ['id', 'created_at', 'updated_at', 'deleted_at', 'type', 'polymorphic_name']}
        end

        if options != email_klass.options_for_indexed_json_deserialized
          email_klass.update!(options_for_indexed_json: options)
        end
      end

      def self.update_global_search_fields(email_klass)
        global = email_klass.global_search_fields&.dup
        ['address', 'owner.polymorphic_name'].each do |a|
           global ||= []
           next if global.include?(a)
           global << a
        end

        if email_klass.global_search_fields != global
          email_klass.update!(global_search_fields: global)
        end
      end

      def self.create_email_attributes(concern)
        attrs_email = []
        email_address_attribute = concern.options.detect {|o| o.name == 'address_attribute'}.value
        attrs_email << {
          name: 'address',
          human_name_fr: 'Adresse',
          human_name_en: 'Address',
          type: 'String',
        } unless email_address_attribute
        email_tag_attribute = concern.options.detect {|o| o.name == 'tag_attribute'}.value
        attrs_email << {
          name: 'tag',
          human_name_fr: 'Libellé',
          human_name_en: 'Tag',
          type: 'Enum',
          values_attributes: [
            {
              name: 'Home',
              human_name_fr: 'Domicile',
              human_name_en: 'Home',
            },
            {
              name: 'Office',
              human_name_fr: 'Bureau',
              human_name_en: 'Office',
            },
            {
              name: 'Other',
              human_name_fr: 'Autre',
              human_name_en: 'Other',
            },
            {
              name: 'Favorite',
              human_name_fr: 'Préférée',
              human_name_en: 'Favorite',
            },
          ],
        } unless email_tag_attribute
        email_consent_attribute = concern.options.detect {|o| o.name == 'global_consent_attribute'}.value
        attrs_email << {
          name: 'global_consent',
          human_name_fr: 'Consentement global',
          human_name_en: 'Global Consent',
          type: 'Boolean',
          locked: true,
        } unless email_consent_attribute
        tracking_pixel_consent_attribute = concern.options.detect {|o| o.name == 'tracking_pixel_consent_attribute'}.value
        attrs_email << {
          name: 'tracking_pixel_consent',
          human_name_fr: 'Consentement pixel de suivi',
          human_name_en: 'Tracking pixel consent',
          type: 'Boolean',
          locked: true,
        } unless tracking_pixel_consent_attribute
        email_npai_attribute = concern.options.detect {|o| o.name == 'npai_attribute'}.value
        attrs_email << {
          name: 'npai',
          human_name_fr: 'Npai',
          human_name_en: 'Npai',
          type: 'Boolean',
        } unless email_consent_attribute
        concern.klass.attrs.create!(attrs_email) unless attrs_email.empty?
        attrs_email.each do |attrs|
          opt = concern.options.detect {|o| o.name.start_with?(attrs[:name])}
          next unless opt
          opt.update!(value: concern.klass.attrs.detect {|a| a.name == attrs[:name]})
        end
      end

      def self.create_email_validations(concern)
        return unless concern.klass.validations.exists?(name: 'validation_mail')
        address_opt = concern.options.detect {|a| a.name == 'address_attribute'}
        concern.klass.validations.create!(
          attr: address_opt.value,
          name: 'validation_mail',
          human_name: 'Validation mail',
          type: 'Dynamic::Schema::Validation::Format::Email',
        )
      end

      def self.create_email_associations(concern)
        email_owner_opt = concern.options.detect {|o| o.name == 'owner_association'}
        unless email_owner_opt.value
          email_owner_association = concern.klass.associations.create!(
            name: 'owner',
            type: 'BelongsTo',
            dependent_destroy: false,
            touch_target: false,
            human_name_fr: 'Propriétaire',
            human_name_en: 'Owner'
          )
          email_owner_opt.update!(value: email_owner_association)
        end
        owner_association = email_owner_opt.value

        contact_emails_opt = concern.options.detect {|o| o.name == 'contact_emails_association'}
        unless contact_emails_opt.value
          contact_klass = concern.feature.options.detect {|k| k.name == 'contact_klass'}.value
          contact_emails_assoc = contact_klass.associations.create!(
            name: 'emails',
            target_klass: concern.klass,
            inverse_of: owner_association,
            type: 'HasMany',
            dependent_destroy: true,
            touch_target: false,
            human_name: 'Emails'
          )
          contact_emails_opt.update!(value: contact_emails_assoc)
        end

        account_emails_opt = concern.options.detect {|o| o.name == 'account_emails_association'}
        account_klass = concern.feature.options.detect {|k| k.name == 'account_klass'}.value
        if account_klass && account_emails_opt.value.nil?
          account_emails_assoc = account_klass.associations.create!(
            name: 'emails',
            target_klass: concern.klass,
            inverse_of: owner_association,
            type: 'HasMany',
            dependent_destroy: true,
            touch_target: false,
            human_name: 'Emails'
          )
          account_emails_opt.update!(value: account_emails_assoc)
        end
      end

      def self.create_phone_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Téléphone',
          human_name_en: 'Phone',
          plural_human_name_fr: 'Téléphones',
          plural_human_name_en: 'Phones',
          icon: 'phone',
          table_profile: :medium,
        ).find_or_create_by!(name: 'Phone')
      end

      def self.create_phone_attributes(concern)
        attrs_phone = []
        phone_number_attribute = concern.options.detect {|o| o.name == 'number_attribute'}.value
        attrs_phone << {
          name: 'number',
          human_name_fr: 'Numéro',
          human_name_en: 'Number',
          type: 'String',
        } unless phone_number_attribute
        phone_tag_attribute = concern.options.detect {|o| o.name == 'tag_attribute'}.value
        attrs_phone << {
          name: 'tag',
          human_name_fr: 'Libellé',
          human_name_en: 'Tag',
          type: 'Enum',
          values_attributes: [
            {
              name: 'Mobile',
              human_name_fr: 'Mobile',
              human_name_en: 'Mobile',
            },
            {
              name: 'Home',
              human_name_fr: 'Domicile',
              human_name_en: 'Home',
            },
            {
              name: 'Office',
              human_name_fr: 'Bureau',
              human_name_en: 'Office',
            },
            {
              name: 'Other',
              human_name_fr: 'Autre',
              human_name_en: 'Other',
            },
            {
              name: 'Favorite',
              human_name_fr: 'Préféré',
              human_name_en: 'Favorite',
            },
          ],
        } unless phone_tag_attribute
        concern.klass.attrs.create!(attrs_phone) unless attrs_phone.empty?
        attrs_phone.each do |attrs|
          opt = concern.options.detect {|o| o.name.start_with?(attrs[:name])}
          next unless opt
          opt.update!(value: concern.klass.attrs.detect {|a| a.name == attrs[:name]})
        end
      end

      def self.create_phone_validations(concern)
        return unless concern.klass.validations.exists?(name: 'validation_telephone')
        number_opt = concern.options.detect {|a| a.name == 'number_attribute'}
        concern.klass.validations.create!(
          attr: number_opt.value,
          name: 'validation_telephone',
          human_name: 'Validation téléphone',
          type: 'Dynamic::Schema::Validation::Format::InternationalPhoneNumber'
        )
      end

      def self.create_phone_associations(concern)
        phone_owner_opt = concern.options.detect {|o| o.name == 'owner_association'}
        unless phone_owner_opt.value
          phone_owner_assoc = concern.klass.associations.create!(
            name: 'owner',
            type: 'BelongsTo',
            dependent_destroy: false,
            touch_target: false,
            human_name_fr: 'Propriétaire',
            human_name_en: 'Owner'
          )
          phone_owner_opt.update!(value: phone_owner_assoc)
        end
        owner_association = phone_owner_opt.value

        contact_phones_opt = concern.options.detect {|o| o.name == 'contact_phones_association'}
        unless contact_phones_opt.value
          contact_klass = concern.feature.options.detect {|k| k.name == 'contact_klass'}.value
          contact_phones_assoc = contact_klass.associations.create!(
            name: 'phones',
            target_klass: concern.klass,
            inverse_of: owner_association,
            type: 'HasMany',
            dependent_destroy: true,
            touch_target: false,
            human_name_fr: 'Téléphones',
            human_name_en: 'Phones'
          )
          contact_phones_opt.update!(value: contact_phones_assoc)
        end

        account_phones_opt = concern.options.detect {|o| o.name == 'account_phones_association'}
        account_klass = concern.feature.options.detect {|k| k.name == 'account_klass'}.value
        if account_klass && account_phones_opt.value.nil?
          account_phones_assoc = account_klass.associations.create!(
            name: 'phones',
            target_klass: concern.klass,
            inverse_of: owner_association,
            type: 'HasMany',
            dependent_destroy: true,
            touch_target: false,
            human_name_fr: 'Téléphones',
            human_name_en: 'Phones'
          )
          account_phones_opt.update!(value: account_phones_assoc)
        end
      end

      def self.create_address_klass(feature)
        return feature.schema.klasses.create_with(
          human_name_fr: 'Adresse',
          human_name_en: 'Address',
          plural_human_name_fr: 'Adresses',
          plural_human_name_en: 'Addresses',
          icon: 'map-marker-alt',
          table_profile: :medium,
        ).find_or_create_by!(name: 'Address')
      end

      def self.create_address_attributes(concern)
        attrs_address = []
        tag_attribute = concern.options.detect {|o| o.name == 'tag_attribute'}.value
        attrs_address << {
          name: 'tag',
          human_name_fr: 'Libellé',
          human_name_en: 'Tag',
          type: 'Enum',
          values_attributes: [
            {
              name: 'Home',
              human_name_fr: 'Domicile',
              human_name_en: 'Home',
            },
            {
              name: 'Office',
              human_name_fr: 'Bureau',
              human_name_en: 'Office',
            },
            {
              name: 'Other',
              human_name_fr: 'Autre',
              human_name_en: 'Other',
            },
            {
              name: 'Favorite',
              human_name_fr: 'Préféré',
              human_name_en: 'Favorite',
            },
          ],
        } unless tag_attribute
        street_attribute = concern.options.detect {|o| o.name == 'street_attribute'}.value
        attrs_address << {
          name: 'street',
          human_name_fr: 'Rue',
          human_name_en: 'Street',
          type: 'String',
        } unless street_attribute
        second_street_attribute = concern.options.detect {|o| o.name == 'second_street_attribute'}.value
        attrs_address << {
          name: 'second_street',
          human_name_fr: 'Complément 1',
          human_name_en: 'Second street',
          type: 'String',
        } unless second_street_attribute
        third_street_attribute = concern.options.detect {|o| o.name == 'third_street_attribute'}.value
        attrs_address << {
          name: 'third_street',
          human_name_fr: 'Complément 2',
          human_name_en: 'Third street',
          type: 'String',
        } unless third_street_attribute
        delivery_mention = concern.options.detect {|o| o.name == 'delivery_mention_attribute'}.value
        attrs_address << {
          name: 'delivery_mention',
          human_name_fr: 'Mention de livraison',
          human_name_en: 'Delivery mention',
          type: 'String',
        } unless delivery_mention
        zip_code_attribute = concern.options.detect {|o| o.name == 'zip_code_attribute'}.value
        attrs_address << {
          name: 'zip_code',
          human_name_fr: 'Code postal',
          human_name_en: 'Zip code',
          type: 'String',
        } unless zip_code_attribute
        city_attribute = concern.options.detect {|o| o.name == 'city_attribute'}.value
        attrs_address << {
          name: 'city',
          human_name_fr: 'Ville',
          human_name_en: 'City',
          type: 'String',
        } unless city_attribute
        second_delivery_mention = concern.options.detect {|o| o.name == 'second_delivery_mention_attribute'}.value
        attrs_address << {
          name: 'second_delivery_mention',
          human_name_fr: 'Seconde mention de livraison',
          human_name_en: 'Second delivery mention',
          type: 'String',
        } unless second_delivery_mention
        country_attribute = concern.options.detect {|o| o.name == 'country_attribute'}.value
        attrs_address << {
          name: 'country',
          human_name_fr: 'Pays',
          human_name_en: 'Country',
          type: 'String',
        } unless country_attribute
        complete_name = concern.options.detect {|o| o.name == 'name_attribute'}.value
        attrs_address << {
          human_name_fr: 'Nom complet',
          human_name_en: 'Complete name',
          name: 'name',
          formula: %Q[join(compact([#{attrs_address.map {|a| a[:name]}.join(', ')}]), ", ")],
          type: 'String',
        } unless complete_name
        county_attribute = concern.options.detect {|o| o.name == 'county_attribute'}.value
        attrs_address << {
          name: 'county',
          human_name_fr: 'Département',
          human_name_en: 'County',
          type: 'String',
        } unless county_attribute
        state_attribute = concern.options.detect {|o| o.name == 'state_attribute'}.value
        attrs_address << {
          name: 'state',
          human_name_fr: 'Région',
          human_name_en: 'State',
          type: 'String',
        } unless state_attribute
        latitude_attribute = concern.options.detect {|o| o.name == 'latitude_attribute'}.value
        attrs_address << {
          name: 'latitude',
          human_name_fr: 'Latitude',
          human_name_en: 'Latitude',
          type: 'Float',
        } unless latitude_attribute
        longitude_attribute = concern.options.detect {|o| o.name == 'longitude_attribute'}.value
        attrs_address << {
          name: 'longitude',
          human_name_fr: 'Longitude',
          human_name_en: 'Longitude',
          type: 'Float',
        } unless longitude_attribute
        concern.klass.attrs.create!(attrs_address) unless attrs_address.empty?
        attrs_address.each do |attrs|
          opt = concern.options.detect {|o| o.name.start_with?(attrs[:name])}
          next unless opt
          opt.update!(value: concern.klass.attrs.detect {|a| a.name == attrs[:name]})
        end
      end

      def self.create_address_associations(concern)
        address_owner_opt = concern.options.detect {|o| o.name == 'owner_association'}
        unless address_owner_opt.value
          address_owner_assoc = concern.klass.associations.create!(
            name: 'owner',
            type: 'BelongsTo',
            dependent_destroy: false,
            touch_target: false,
            human_name_fr: 'Propriétaire',
            human_name_en: 'Owner'
          )
          address_owner_opt.update!(value: address_owner_assoc)
        end
        owner_association = address_owner_opt.value

        contact_addresses_opt = concern.options.detect {|o| o.name == 'contact_addresses_association'}
        unless contact_addresses_opt.value
          contact_klass = concern.feature.options.detect {|k| k.name == 'contact_klass'}.value
          contact_addresses_assoc = contact_klass.associations.create!(
            name: 'addresses',
            target_klass: concern.klass,
            inverse_of: owner_association,
            type: 'HasMany',
            dependent_destroy: true,
            touch_target: false,
            human_name_fr: 'Adresses',
            human_name_en: 'Addresses'
          )
          contact_addresses_opt.update!(value: contact_addresses_assoc)
        end

        account_addresses_opt = concern.options.detect {|o| o.name == 'account_addresses_association'}
        account_klass = concern.feature.options.detect {|k| k.name == 'account_klass'}.value
        if account_klass && account_addresses_opt.value.nil?
          account_addresses_assoc = account_klass.associations.create!(
            name: 'addresses',
            target_klass: concern.klass,
            inverse_of: owner_association,
            type: 'HasMany',
            dependent_destroy: true,
            touch_target: false,
            human_name_fr: 'Adresses',
            human_name_en: 'Addresses'
          )
          account_addresses_opt.update!(value: account_addresses_assoc)
        end
      end

      def self.create_email_contact(feature, email_klass)
        email_contact_association_attr = {name: 'email_contact', type: 'HasMany', human_name_fr: 'Email de contact', human_name_en: 'Contact email', target_klass: email_klass}
        feature.schema.klasses.each do |k|
          associations = k.associations.select{|a| a.target_klass_id == email_klass.id}
          if associations.any?
            k.associations.create!(email_contact_association_attr) unless k.associations.where(name: 'email_contact').exists?
          end
        end
      end

      def self.create_phone_contact(feature, phone_klass)
        phone_contact_association_attr = {name: 'phone_contact', type: 'HasMany', human_name_fr: 'Téléphone de contact', human_name_en: 'Contact phone', target_klass: phone_klass}
        feature.schema.klasses.each do |k|
          associations = k.associations.select{|a| a.target_klass_id == phone_klass.id}
          if associations.any?
            k.associations.create!(phone_contact_association_attr) unless k.associations.where(name: 'phone_contact').exists?
          end
        end
      end

      def self.create_address_contact(feature, address_klass)
        address_contact_association_attr = {name: 'address_contact', type: 'HasMany', human_name_fr: 'Adresse de contact', human_name_en: 'Contact address', target_klass: address_klass}
        feature.schema.klasses.each do |k|
          associations = k.associations.select{|a| a.target_klass_id == address_klass.id}
          if associations.any?
            k.associations.create!(address_contact_association_attr) unless k.associations.where(name: 'address_contact').exists?
          end
        end
      end

      def self.compute_email_contact(record)
        klass = record&.class
        return unless klass.respond_to? :reflect_on_association
        email_contact_association = klass&.reflect_on_association('email_contact')
        return unless email_contact_association

        split = klass.name.split('::')
        klass_name = split.last.downcase.pluralize
        email_orders = "D::#{split.second}::R::EmailOrder::Base".safe_constantize.where(klass: klass_name)
        email_orders.each do |e_o|
          filter = e_o.filters || {}
          filter['id'] = {"contains"=>record.id}
          if klass.where_filters(filter).count == 1
            e_o.sorted_types.each do |t|
              tag = t[1]
              emails = record.emails.where(tag: tag)
              if emails.any?
                record.update!(email_contact: emails)
                return
              end
            end
          end
        end
        record.update!(email_contact: [])
      end

      def self.compute_all_email_contact(schema_name, email_order)
        filter = email_order.filters
        klass = "D::#{schema_name.classify}::#{email_order.klass.classify}".safe_constantize
        return unless klass

        ids_done = []
        email_order.sorted_types.each do |t|
          tag = t[1]
          klass.where_filters(filter).where.not(id: ids_done).includes(:emails).where(emails: {tag: tag}).each do |r|
            r.update!(email_contact: r.emails.where(tag: tag))
            ids_done << r.id
          end
        end
        return true
      end

      def self.load(schema)
        email_order = ::Dynamic::EmailOrder::Base.mount(schema)
        email_type = ::Dynamic::EmailOrder::Type.mount(schema)

        if schema.feature_enabled?('Dynamic::Elasticsearch::Feature')
          feature = schema.features.detect {|e| e.name == self.name} # TODO should be provided as a parameter of self.load
          Dynamic::Elasticsearch::Feature.include_opensearch_model(email_order, feature)
        end
        return true
      end

      class Worker
        include ::Sidekiq::Worker
        include ::Dynamic::Worker
        sidekiq_options queue: 'low', retry: 0

        def perform(args)
          return unless args.keys.include? 'klass_name'
          return unless args.keys.include? 'id'
          schema_name = args['klass_name'].split('::')[1]
          if schema_name
            ::Dynamic::Schema.load(schema_name) do
              klass = args['klass_name'].constantize
              record = klass.find_by_id(args['id'])
              return unless record
              record.__opensearch__.update_document
              ::OpenSearch::Model.refresh
              Dynamic::Communication::Feature.compute_email_contact(record)
            end
          end
        end
      end

      module DynamicRecord; extend ActiveSupport::Concern
        included do
          after_commit :__compute_email_contact_async, on: :create
          after_update :__compute_email_contact, unless: :__locked_compute_email_contact?

          def __compute_email_contact
            begin
              Thread.current[:__compute_email_contact_lock] = true
              Dynamic::Communication::Feature.compute_email_contact(self)
              # recompute owner, beurk
              owner_association_name = "owner"
              return unless self.class.reflect_on_association(owner_association_name)
              owner = self.send(owner_association_name)
              return unless owner
              Dynamic::Communication::Feature.compute_email_contact(owner)
            ensure
              Thread.current[:__compute_email_contact_lock] = false
            end
          end

          def __compute_email_contact_async
            return unless self.class.respond_to? :reflect_on_association
            email_contact_association = self.class&.reflect_on_association('email_contact')
            return unless email_contact_association

            perform_params = {
              'klass_name' => self.class.name,
              'id' => self.id,
              'user_id' => User&.current&.id,
            }
            Dynamic::Communication::Feature::Worker.perform_async(perform_params)
          end

          def __locked_compute_email_contact?
            Thread.current[:__compute_email_contact_lock] == true
          end
        end
      end

    end

  end
end
