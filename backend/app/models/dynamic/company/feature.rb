module Dynamic
  module Company
    module Feature; extend Dynamic::Feature
      def self.feature_attributes
        {
          human_name_fr: 'Organisation & Établissement',
          human_name_en: 'Organization & Establissement',
          mandatory: false,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Establissement',
              human_name_fr: 'Établissement',
              human_name_en: 'Establissement',
              options_attributes: [
                {
                  name: 'siret_attribute',
                  human_name_fr: 'Attribut SIRET du établissement',
                  human_name_en: "Establissement's SIRET attribute",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'name_attribute',
                  human_name_fr: "Attribut dénomination du établissement",
                  human_name_en: "Establissement's name attribute",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'legal_category_attribute',
                  human_name_fr: 'Attribut catégorie juridique du établissement',
                  human_name_en: "Establissement's legal category attribute",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'ape_attribute',
                  human_name_fr: 'Attribut code APE',
                  human_name_en: 'APE code attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'creation_date_attribute',
                  human_name_fr: 'Attribut date de création du établissement',
                  human_name_en: "Establissement's creation date attribute",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'closing_date_attribute',
                  human_name_fr: 'Attribut date de clôture du établissement',
                  human_name_en: "Establissement's closing date attribute",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'logo_attachment',
                  human_name_fr: 'Logo du établissement',
                  human_name_en: "Establissement's logo attachment",
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'organization_association',
                  human_name_fr: "Association vers l'organisation",
                  human_name_en: 'Association to the organization',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Organization',
              human_name_fr: 'Organisation',
              human_name_en: 'Organization',
              options_attributes: [
                {
                  name: 'name_attribute',
                  human_name_fr: 'Attribut dénomination',
                  human_name_en: 'Name attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'siren_attribute',
                  human_name_fr: 'Attribut SIREN',
                  human_name_en: 'SIREN attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'legal_category_attribute',
                  human_name_fr: 'Attribut catégorie juridique',
                  human_name_en: 'Legal category attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'headquarters_siret_attribute',
                  human_name_fr: 'Attribut SIRET du siège',
                  human_name_en: 'Headquarters SIRET attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'creation_date_attribute',
                  human_name_fr: 'Attribut date de création',
                  human_name_en: 'Creation date attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'closing_date_attribute',
                  human_name_fr: 'Attribut date de clôture',
                  human_name_en: 'Closing date attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'logo_attachment',
                  human_name_fr: 'Pièce jointe logo',
                  human_name_en: 'Logo attachment',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'establissement_association',
                  human_name_fr: 'Association vers les établissement',
                  human_name_en: 'Association to establissements',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'shareholdings_association',
                  human_name_fr: 'Association vers les participations détenues',
                  human_name_en: 'Association to held shareholdings',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'shareholders_association',
                  human_name_fr: 'Association vers les actionnaires',
                  human_name_en: 'Association to shareholders',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Shareholding',
              human_name_fr: 'Participation',
              human_name_en: 'Shareholding',
              options_attributes: [
                {
                  name: 'percentage_attribute',
                  human_name_fr: 'Attribut pourcentage',
                  human_name_en: 'Percentage attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'parent_association',
                  human_name_fr: "Association vers l'organisation mère",
                  human_name_en: 'Association to the parent organization',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'subsidiary_association',
                  human_name_fr: 'Association vers la filiale',
                  human_name_en: 'Association to the subsidiary',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            }
          ],
          options_attributes: [
            {
              name: 'match_comptes_after_enable',
              human_name_fr: 'Rattacher les établissements existants aux entreprises',
              human_name_en: 'Match existing establissement to companies',
              type: 'Boolean',
              value: true
            },
          ]
        }
      end

      def self.after_enabled(feature)
        establissement_concern = feature.concerns.detect{ |c| c.name == 'Establissement'}

        unless establissement_concern.klass
          establissement_concern.update!(klass: create_establissement_klass(feature.schema))
          map_establissement_attributes(establissement_concern)
          map_organization_establissement_attachments(establissement_concern)
        else
          name_option = establissement_concern.options.detect {|o| o.name == 'name_attribute'}
          siret_option = establissement_concern.options.detect {|o| o.name == 'siret_attribute'}
          unless name_option.value && siret_option.value
            establissement_concern.errors.add(:name_attribute, :blank) unless name_option.value
            establissement_concern.errors.add(:siret_attribute, :blank) unless siret_option.value
            raise ActiveRecord::RecordInvalid.new(establissement_concern)
          end
        end

        organization_concern = feature.concerns.detect {|c| c.name == 'Organization'}
        organization_concern.update!(klass: create_organization_klass(feature.schema)) unless organization_concern.klass

        map_organization_attributes(organization_concern)
        map_organization_establissement_attachments(organization_concern)
        map_account_associations(organization_concern, establissement_concern)

        shareholding_concern = feature.concerns.detect {|c| c.name == 'Shareholding'}
        shareholding_concern.update!(klass: create_shareholding_klass(feature.schema)) unless shareholding_concern.klass

        map_shareholding(organization_concern, shareholding_concern)
      end

      def self.after_enabled_and_commit_schema(feature)
        match_option = feature.options.detect {|o| o.name == 'match_comptes_after_enable'}
        return unless match_option.value

        match_option.update!(value: false)
        self.match_all_establissements_async(feature)
      end

      def self.match_all_establissements_async(feature)
        establissement_concern = feature.concerns.detect {|c| c.name == 'Establissement'}
        organization_association = establissement_concern.options.detect {|o| o.name == 'organization_association'}&.value&.name

        klass_name = establissement_concern.klass.const_absolute_name

        feature.schema.load

        notification = create_match_notification(klass_name)

        perform_params = {
          klass_name: klass_name,
          user_id: User.current&.id,
          params: { where: { organization_association => nil } },
          notification: notification,
        }.deep_stringify_keys
        Dynamic::Company::Worker.perform_async(perform_params)
      end

      def self.create_match_notification(klass_name)
        notification_klass = klass_name.safe_constantize.module_parent::R::Notification
        title = I18n.t('company.titles.match_organizations', klass: klass_name.safe_constantize.model_name.human(count: 2).downcase)
        notification_klass&.create!(
          user_id: User.current&.id,
          title: title,
          klass_name: 'Company',
          total: klass_name.safe_constantize&.count,
          data: { klass_name: klass_name },
          can_cancel: true,
        )
      end

      private

      def self.create_establissement_klass(schema)
        schema.klasses.create_with(
          human_name_fr: 'Établissement',
          human_name_en: 'Establissement',
          plural_human_name_fr: 'Établissements',
          plural_human_name_en: 'Establissements',
          table_profile: :medium,
          icon: 'industry',
        ).find_or_create_by!(name: 'Establissement')
      end

      def self.create_organization_klass(schema)
        schema.klasses.create_with(
          human_name_fr: 'Organisation',
          human_name_en: 'Organization',
          plural_human_name_fr: 'Organisations',
          plural_human_name_en: 'Organizations',
          table_profile: :medium,
          icon: 'building',
        ).find_or_create_by!(name: 'Organization')
      end

      def self.create_shareholding_klass(schema)
        schema.klasses.create_with(
          human_name_fr: 'Participation',
          human_name_en: 'Shareholding',
          plural_human_name_fr: 'Participations',
          plural_human_name_en: 'Shareholdings',
          table_profile: :medium,
          icon: 'chart-pie',
        ).find_or_create_by!(name: 'Shareholding')
      end

      def self.map_establissement_attributes(concern)
        _name_attr, siret_attr, _ape_att, creation_date_attr,
        closing_date_attr = assign_options_values(concern,
          [
            {
              type: 'Attr',
              option_name: 'name_attribute',
              mandatory_attributes: {
                name: 'name',
                type: 'String'
              },
              optional_attributes: {
                human_name_fr: 'Dénomination',
                human_name_en: 'Name',
              }
            },
            {
              type: 'Attr',
              option_name: 'siret_attribute',
              mandatory_attributes: {
                name: 'siret',
                type: 'String',
              },
              optional_attributes: {
                human_name_fr: 'SIRET',
                human_name_en: 'SIRET',
              }
            },
            {
              type: 'Attr',
              option_name: 'ape_attribute',
              mandatory_attributes: {
                name: 'ape',
                type: 'String',
              },
              optional_attributes: {
                human_name_fr: 'Code APE',
                human_name_en: 'APE code',
              }
            },
            {
              type: 'Attr',
              option_name: 'creation_date_attribute',
              mandatory_attributes: {
                name: 'creation_date',
                type: 'Date',
              },
              optional_attributes: {
                human_name_fr: 'Date de création',
                human_name_en: 'Creation date',
              }
            },
            {
              type: 'Attr',
              option_name: 'closing_date_attribute',
              mandatory_attributes: {
                name: 'closing_date',
                type: 'Date',
              },
              optional_attributes: {
                human_name_fr: 'Date de clôture',
                human_name_en: 'Closing date',
              }
            },
          ]
        )

        establissement_klass = concern.klass

        establissement_klass.validations.create_with(
          type: 'Format::Siret',
          human_name_fr: 'Format SIRET',
          human_name_en: 'SIRET format',
        ).find_or_create_by!(
          attr_id: siret_attr.id,
          name: 'siret_format_validator',
        )

        siret_attr.normalizations.find_or_create_by!(type: 'Siret')

        establissement_klass.validations.create_with(
          human_name_fr: 'SIRET unique',
          human_name_en: 'Unique SIRET',
          attr_ids: [siret_attr.id],
        ).find_or_create_by!(
          type: 'Uniqueness',
          name: 'siret_uniqueness_validator',
        )

        establissement_klass.validations.create_with(
          type: 'Comparison::Attribute',
          operator: :less_than,
          comparison_attr_id: closing_date_attr.id,
          human_name_fr: 'Avant date de clôture',
          human_name_en: 'Before closing date',
        ).find_or_create_by!(
          attr_id: creation_date_attr.id,
          name: 'creation_date_less_than_closing_date',
        )
      end

      def self.map_organization_attributes(concern)
        _name_attr, siren_attr, _legal_category_attr, creation_date_attr,
        closing_date_attr = assign_options_values(concern,
          [
            {
              type: 'Attr',
              option_name: 'name_attribute',
              mandatory_attributes: {
                name: 'name',
                type: 'String',
              },
              optional_attributes: {
                human_name_fr: 'Dénomination',
                human_name_en: 'Organization name',
              }
            },
            {
              type: 'Attr',
              option_name: 'siren_attribute',
              mandatory_attributes: {
                name: 'siren',
                type: 'String',
              },
              optional_attributes: {
                human_name_fr: 'SIREN',
                human_name_en: 'SIREN',
              }
            },
            {
              type: 'Attr',
              option_name: 'legal_category_attribute',
              mandatory_attributes: {
                name: 'legal_category',
                type: 'Enum',
              },
              optional_attributes: {
                human_name_fr: 'Catégorie juridique',
                human_name_en: 'Legal category',
                values_attributes: [
                  { name: 'sarl', human_name_fr: 'SARL', human_name_en: 'SARL' },
                  { name: 'sas', human_name_fr: 'SAS', human_name_en: 'SAS' },
                  { name: 'sasu', human_name_fr: 'SASU', human_name_en: 'SASU' },
                  { name: 'sa', human_name_fr: 'SA', human_name_en: 'SA' },
                  { name: 'eurl', human_name_fr: 'EURL', human_name_en: 'EURL' },
                  { name: 'sci', human_name_fr: 'SCI', human_name_en: 'SCI' },
                  { name: 'ei', human_name_fr: 'Entrepreneur individuel', human_name_en: 'Sole proprietor' },
                  { name: 'association', human_name_fr: 'Association', human_name_en: 'Non-profit' },
                  { name: 'other', human_name_fr: 'Autre', human_name_en: 'Other' },
                ]
              }
            },
            {
              type: 'Attr',
              option_name: 'creation_date_attribute',
              mandatory_attributes: {
                name: 'creation_date',
                type: 'Date',
              },
              optional_attributes: {
                human_name_fr: 'Date de création',
                human_name_en: 'Creation date',
              }
            },
            {
              type: 'Attr',
              option_name: 'closing_date_attribute',
              mandatory_attributes: {
                name: 'closing_date',
                type: 'Date',
              },
              optional_attributes: {
                human_name_fr: 'Date de clôture',
                human_name_en: 'Closing date',
              }
            },
            {
              type: 'Attr',
              option_name: 'headquarters_siret_attribute',
              mandatory_attributes: {
                name: 'headquarters_siret',
                type: 'String',
              },
              optional_attributes: {
                human_name_fr: 'SIRET du siège',
                human_name_en: 'Headquarters SIRET',
              }
            },
          ]
        )

        organization_klass = concern.klass

        organization_klass.validations.create_with(
          type: 'Format::Siren',
          human_name_fr: 'Format SIREN',
          human_name_en: 'SIREN format',
        ).find_or_create_by!(
          attr_id: siren_attr.id,
          name: 'siren_format_validator',
        )

        siren_attr.normalizations.find_or_create_by!(type: 'Siret')

        organization_klass.validations.create_with(
          human_name_fr: 'SIREN unique',
          human_name_en: 'Unique SIREN',
          attr_ids: [siren_attr.id],
        ).find_or_create_by!(
          type: 'Uniqueness',
          name: 'siren_uniqueness_validator',
        )

        organization_klass.validations.create_with(
          type: 'Comparison::Attribute',
          operator: :less_than,
          comparison_attr_id: closing_date_attr.id,
          human_name_fr: 'Avant date de clôture',
          human_name_en: 'Before closing date',
        ).find_or_create_by!(
          attr_id: creation_date_attr.id,
          name: 'creation_date_less_than_closing_date',
        )
      end

      def self.map_organization_establissement_attachments(concern)
        assign_options_values(concern,
          [
            {
              type: 'Attach',
              option_name: 'logo_attachment',
              mandatory_attributes: {
                name: 'logo',
                type: 'HasOne',
              },
              optional_attributes: {
                human_name_fr: 'Logo',
                human_name_en: 'Logo',
                extensions: ['png', 'jpg', 'jpeg'],
              }
            },
          ]
        )
      end

      def self.map_account_associations(organization_concern, establishement_concern)
        organization_klass = organization_concern.klass
        establishement_klass = establishement_concern.klass

        establissements_assoc = assign_options_values(
          organization_concern, [
            {
              type: 'Assoc',
              option_name: 'establissement_association',
              mandatory_attributes: {
                name: 'establissements',
                type: 'HasMany',
                target_klass: establishement_klass,
              },
              optional_attributes: {
                human_name_fr: 'Établissements',
                human_name_en: 'Establissements',
              }
            },
          ]
        ).first

        organization_assoc = assign_options_values(establishement_concern,
          [
            {
              type: 'Assoc',
              option_name: 'organization_association',
              mandatory_attributes: {
                name: 'organization',
                type: 'BelongsTo',
                target_klass: organization_klass,
                inverse_of: establissements_assoc,
              },
              optional_attributes: {
                human_name_fr: 'Organisation',
                human_name_en: 'Organization',
              }
            },
          ]
        ).first

        establissements_assoc.update!(inverse_of: organization_assoc) unless establissements_assoc.inverse_of_id
      end

      def self.map_shareholding(organization_concern, shareholding_concern)
        organization_klass = organization_concern.klass
        shareholding_klass = shareholding_concern.klass

        assign_options_values(shareholding_concern,
          [
            {
              type: 'Attr',
              option_name: 'percentage_attribute',
              mandatory_attributes: {
                name: 'percentage',
                type: 'Float',
              },
              optional_attributes: {
                human_name_fr: 'Pourcentage',
                human_name_en: 'Percentage',
              }
            },
          ]
        )

        shareholdings_assoc = assign_options_values(organization_concern,
          [
            {
              type: 'Assoc',
              option_name: 'shareholdings_association',
              mandatory_attributes: {
                name: 'shareholdings',
                type: 'HasMany',
                target_klass: shareholding_klass,
              },
              optional_attributes: {
                human_name_fr: 'Participations',
                human_name_en: 'Shareholdings',
              }
            },
          ]
        ).first

        parent_assoc = assign_options_values(shareholding_concern,
          [
            {
              type: 'Assoc',
              option_name: 'parent_association',
              mandatory_attributes: {
                name: 'parent',
                type: 'BelongsTo',
                target_klass: organization_klass,
                inverse_of: shareholdings_assoc,
              },
              optional_attributes: {
                human_name_fr: 'Organisation mère',
                human_name_en: 'Parent organization',
              }
            },
          ]
        ).first

        shareholdings_assoc.update!(inverse_of: parent_assoc) unless shareholdings_assoc.inverse_of_id

        shareholders_assoc = assign_options_values(organization_concern,
          [
            {
              type: 'Assoc',
              option_name: 'shareholders_association',
              mandatory_attributes: {
                name: 'shareholders',
                type: 'HasMany',
                target_klass: shareholding_klass,
              },
              optional_attributes: {
                human_name_fr: 'Actionnaires',
                human_name_en: 'Shareholders',
              }
            },
          ]
        ).first

        subsidiary_assoc = assign_options_values(shareholding_concern,
          [
            {
              type: 'Assoc',
              option_name: 'subsidiary_association',
              mandatory_attributes: {
                name: 'subsidiary',
                type: 'BelongsTo',
                target_klass: organization_klass,
                inverse_of: shareholders_assoc,
              },
              optional_attributes: {
                human_name_fr: 'Filiale',
                human_name_en: 'Subsidiary',
              }
            },
          ]
        ).first

        shareholders_assoc.update!(inverse_of: subsidiary_assoc) unless shareholders_assoc.inverse_of_id
      end

      def self.assign_options_values(concern, params)
        result = []

        params.each do |param|
          option = concern.options.detect{|o| o.name == param[:option_name]}
          option_value = option.value
          if option_value
            result << option.value
            next
          end

          method_name = case param[:type]
            when 'Attr' then 'attrs'
            when 'Assoc' then 'associations'
            when 'Attach' then 'attachments'
          end

          unless method_name
            result << nil
            next
          end

          r = concern.klass.send(method_name).create_with(
            param[:optional_attributes]
          ).find_or_create_by!(
            param[:mandatory_attributes]
          )

          option.update!(value: r)
          result << r
        end

        return result
      end

    end
  end
end
