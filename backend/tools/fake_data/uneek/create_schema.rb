#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = ::Dynamic::Schema.where(name: 'Uneek').first

if @schema.nil?
  begin
    ::UneekSsoClient.sync_all!
  rescue
    raise 'Sso must be started and a first authentication must have been made before running this script'
  end
  Dynamic::Schema.loaded_schemas.values.map(&:unload) # TODO when loaded too soon it crashes in form creation. how this can be fixed properly ?
  @schema = ::Dynamic::Schema.where(name: 'Uneek').first
end

puts 'create schema'

@schema.update(
  klasses_attributes: [
    {
      id: '01834078-52df-721b-91ba-4830f86bc7bb',
      human_name_fr: 'Contact',
      human_name_en: 'Contact',
      icon: 'user',
      name_attribute_id: '01834078-b175-7236-84bb-305a24a02d66', # name
      photo_attachment_id: '01834078-b392-700e-9234-08919bd0384a', # photo
      attrs_attributes: [
        {
          id: '01834078-9d11-72f9-a649-92c74a2468de',
          human_name_fr: 'Civilité',
          human_name_en: 'Civility',
          type: 'Enum',
          values_attributes: [
            {
              id: '01834078-9f4e-7320-a8b2-458b90d12bfc',
              human_name_fr: 'Monsieur',
              human_name_en: 'Mr.',
            },
            {
              id: '01834078-a33e-73aa-a1f1-1459df805d6a',
              human_name_fr: 'Madame',
              human_name_en: 'Mrs.',
            },
          ]
        },
        {
          id: '01834078-a52e-728f-bb2c-a67f0b5755a6',
          human_name_fr: 'Prénom',
          human_name_en: 'First name',
          type: 'String',
        },
        {
          id: '01834078-a70f-7318-92c3-ee60ef34d9d2',
          human_name_fr: 'Nom de naissance',
          human_name_en: 'Last name',
          type: 'String',
        },
        {
          id: '01834078-a8e1-71bd-8070-f240d893d06d',
          human_name_fr: 'Genre',
          human_name_en: 'Gender',
          type: 'Enum',
          values_attributes: [
            {
              id: '01834078-adc6-72a6-8271-b7c922209d6d',
              human_name_fr: 'Homme',
              human_name_en: 'Male',
            },
            {
              id: '01834078-af92-727a-ba28-56a5b3f10d85',
              human_name_fr: 'Femme',
              human_name_en: 'Female',
            },
          ]
        },
        {
          id: '01834078-b175-7236-84bb-305a24a02d66',
          human_name_fr: 'Nom',
          human_name_en: 'Name',
          name: 'name',
          formula: %Q[join(compact([first_name, last_name]), " ")],
          type: 'String',
        },
      ],
      attachments_attributes: [
        {
          id: '01834078-b392-700e-9234-08919bd0384a',
          human_name_fr: 'Photo',
          human_name_en: 'Photo',
          type: 'HasOne',
        },
      ],
      associations_attributes: [
        {
          id: '018340be-864d-7356-984a-05f49a93c4e9',
          human_name_fr: 'Entreprise',
          human_name_en: 'Company',
          target_klass_id: '01834078-b615-7338-b200-fa9f4ecbdb24',
          inverse_of_id: '0183413c-2945-71c6-a045-5b9e5b69404f',
          type: 'BelongsTo',
        },
        {
          id: '0183413c-334e-717c-bba5-dd013e564491',
          human_name_fr: 'Adresses',
          human_name_en: 'Addresses',
          target_klass_id: '01834079-2402-7269-8355-2bb929595051',
          inverse_of_id: '0183413c-2c08-72b6-bdad-cc50178ec706',
          dependent_destroy: true,
          type: 'HasMany',
        },
        {
          id: '0183413c-35d2-7045-8e7d-65296d48e4ff',
          human_name_fr: 'Emails',
          human_name_en: 'Emails',
          name: 'emails',
          target_klass_id: '01834079-1280-72e9-a2fa-9caaa3b69c2d',
          inverse_of_id: '0183413c-30a8-733c-b8eb-3c0c1d59479c',
          dependent_destroy: true,
          type: 'HasMany',
        },
        {
          id: '01834150-c065-70c3-8df0-646d65266994',
          human_name_fr: 'Téléphones',
          human_name_en: 'Phones',
          target_klass_id: '01834079-002d-73e5-9642-c94cfcde09ad',
          inverse_of_id: '0183413c-2e6a-723c-9b8c-b6a62425ad00',
          dependent_destroy: true,
          type: 'HasMany',
        }
      ],
    },
    {
      id: '01834078-b615-7338-b200-fa9f4ecbdb24',
      human_name_fr: 'Compte',
      human_name_en: 'Account',
      icon: 'building',
      name_attribute_id: '01834078-bf6a-73c0-8670-8a86ebb1c9a1', # name
      photo_attachment_id: '01834078-caed-713a-bbed-4ac6871d8ed2', # logo
      attrs_attributes: [
        {
          id: '01834078-bf6a-73c0-8670-8a86ebb1c9a1',
          human_name_fr: 'Raison sociale',
          human_name_en: 'Name',
          type: 'String',
        }
      ],
      attachments_attributes: [
        {
          id: '01834078-caed-713a-bbed-4ac6871d8ed2',
          human_name_fr: 'Logo',
          human_name_en: 'Logo',
          type: 'HasOne',
        },
      ],
      associations_attributes: [
        {
          id: '0183413c-2945-71c6-a045-5b9e5b69404f',
          human_name_fr: 'Employés',
          human_name_en: 'Employees',
          target_klass_id: '01834078-52df-721b-91ba-4830f86bc7bb',
          inverse_of_id: '018340be-864d-7356-984a-05f49a93c4e9',
          type: 'HasMany',
        },
        {
          id: '01834150-c27a-736e-a0e8-4ee379fdc1ee',
          human_name_fr: 'Adresses',
          human_name_en: 'Addresses',
          target_klass_id: '01834079-2402-7269-8355-2bb929595051',
          inverse_of_id: '0183413c-2c08-72b6-bdad-cc50178ec706',
          dependent_destroy: true,
          type: 'HasMany',
        },
        {
          id: '01834150-c484-726a-872f-5b1d355fabae',
          human_name_fr: 'Emails',
          human_name_en: 'Emails',
          target_klass_id: '01834079-1280-72e9-a2fa-9caaa3b69c2d',
          inverse_of_id: '0183413c-30a8-733c-b8eb-3c0c1d59479c',
          dependent_destroy: true,
          type: 'HasMany',
        },
        {
          id: '01834150-c684-70a5-b0b1-b75a581ba222',
          human_name_fr: 'Téléphones',
          human_name_en: 'Phones',
          target_klass_id: '01834079-002d-73e5-9642-c94cfcde09ad',
          inverse_of_id: '0183413c-2e6a-723c-9b8c-b6a62425ad00',
          dependent_destroy: true,
          type: 'HasMany',
         }
      ],
    },
    {
      id: '01834079-002d-73e5-9642-c94cfcde09ad',
      human_name_fr: 'Téléphone',
      human_name_en: 'Phone',
      icon: 'phone',
      name_attribute_id: '01834079-01ff-7186-a198-6c8332c0933a', # number
      attrs_attributes: [
        {
          id: '01834079-01ff-7186-a198-6c8332c0933a',
          human_name_fr: 'Numéro',
          human_name_en: 'Number',
          type: 'String',
        },
        {
          id: '01834079-043e-735d-98c1-1de0ecec9c18',
          human_name_fr: 'Libellé',
          human_name_en: 'Tag',
          name: 'tag',
          type: 'Enum',
          values_attributes: [
            {
              id: '01834079-05db-73c3-a67c-1a51908f8195',
              human_name_fr: 'Mobile',
              human_name_en: 'Mobile',
            },
            {
              id: '01834079-078f-72e2-b318-3ad10b0bba7b',
              human_name_fr: 'Domicile',
              human_name_en: 'Home',
            },
            {
              id: '01834079-093c-7380-b104-321001bf4a13',
              human_name_fr: 'Bureau',
              human_name_en: 'Office',
            },
            {
              id: '01834079-0afe-71b5-bbbb-271f528bf66e',
              human_name_fr: 'Fax Domicile',
              human_name_en: 'Fax Home',
            },
            {
              id: '01834079-0c8f-7351-a917-572750b7361d',
              human_name_fr: 'Fax Bureau',
              human_name_en: 'Fax Office',
            },
            {
              id: '01834079-0e31-7278-b9d5-8e554a7d1c08',
              human_name_fr: 'Autre',
              human_name_en: 'Other',
            },
          ]
        },
      ],
      associations_attributes: [
        {
          id: '0183413c-2e6a-723c-9b8c-b6a62425ad00',
          human_name_fr: 'propriétaire',
          human_name_en: 'owner',
          type: 'BelongsTo', # polymorphic
        }
      ],
    },
    {
      id: '01834079-1280-72e9-a2fa-9caaa3b69c2d',
      human_name_fr: 'Email',
      human_name_en: 'Email',
      name: 'email',
      icon: 'envelope',
      name_attribute_id: '01834079-144f-7070-81a9-4b6a5d622737', # address
      attrs_attributes: [
        {
          id: '01834079-144f-7070-81a9-4b6a5d622737',
          human_name_fr: 'Adresse',
          human_name_en: 'Address',
          type: 'String',
        },
        {
          id: '01834079-15f6-7331-8d0f-5535d8fc4d3f',
          human_name_fr: 'Libellé',
          human_name_en: 'Tag',
          name: 'tag',
          type: 'Enum',
          values_attributes: [
            {
              id: '01834079-17bc-7356-8310-f1619a010c57',
              human_name_fr: 'Domicile',
              human_name_en: 'Home',
            },
            {
              id: '01834079-1cc7-70a3-8112-e9c0f72a3829',
              human_name_fr: 'Bureau',
              human_name_en: 'Office',
            },
            {
              id: '01834079-21a7-72e5-a3c6-2b8ba6edcdcc',
              human_name_fr: 'Autre',
              human_name_en: 'Other',
            },
          ]
        }
      ],
      associations_attributes: [
        {
          id: '0183413c-30a8-733c-b8eb-3c0c1d59479c',
          human_name_fr: 'propriétaire',
          human_name_en: 'owner',
          type: 'BelongsTo', # polymorphic
        }
      ],
    },
    {
      id: '01834079-2402-7269-8355-2bb929595051',
      human_name_fr: 'Adresse',
      human_name_en: 'Address',
      icon: 'map-marker-alt',
      name_attribute_id: '018340ba-0104-7294-899a-b6b1e92cd840', # name
      attrs_attributes: [
        {
          id: '018340ba-0104-7294-899a-b6b1e92cd840',
          human_name_fr: 'Nom complet',
          human_name_en: 'Complete name',
          name: 'name',
          formula: 'join(compact([street, second_street, third_street, delivery_mention, zip_code, city, second_delivery_mention, country]), ", ")',
          type: 'String',
        },
        {
          id: '018340ba-06fe-7326-93b4-3f1d3bc573a4',
          human_name_fr: 'Rue',
          human_name_en: 'Street',
          name: 'street',
          type: 'String',
        },
        {
          id: '018340ba-0937-70dd-b08a-a267394701d9',
          human_name_fr: 'Complément 1',
          human_name_en: 'Second street', # TODO rename
          name: 'second_street',
          type: 'String',
        },
        {
          id: '018340ba-0b2d-724c-a512-7c087897ff5d',
          human_name_fr: 'Complément 2',
          human_name_en: 'Third street', # TODO rename
          name: 'third_street',
          type: 'String',
        },
        {
          id: '018340ba-0da7-7042-ae08-ac8fb628675d',
          human_name_fr: 'Mention de livraison',  # eg: BP 12345, CS 12345, TSA, SP, CE
          human_name_en: 'Delivery mention',
          type: 'String',
        },
        {
          id: '018340ba-1033-73e5-8119-dec23431d55d',
          human_name_fr: 'Code postal',
          human_name_en: 'Zip code',
          type: 'String',
        },
        {
          id: '018340ba-1333-7185-b6f3-713255256240',
          human_name_fr: 'Ville',
          human_name_en: 'City',
          name: 'city',
          type: 'String',
        },
        {
          id: '018340ba-1582-701b-ba2f-2b12c077b2db',
          human_name_fr: 'Seconde mention de livraison', # eg: CEDEX 01, CIDEX
          human_name_en: 'Second delivery mention',
          type: 'String',
        },
        {
          id: '018340bc-9d81-72d8-adb2-cc6551a0dee9',
          human_name_fr: 'Département',
          human_name_en: 'County',
          type: 'String',
        },
        {
          id: '018340bc-a254-70c6-b616-bffe325c4fcc',
          human_name_fr: 'Région',
          human_name_en: 'State',
          type: 'String',
        },
        {
          id: '018340bc-a490-70f5-8857-041eb31fc7a0',
          human_name_fr: 'Pays',
          human_name_en: 'Country',
          type: 'String',
        },
        {
          id: '018340bc-a6ba-728f-85b3-67cf81bc6b50',
          human_name_fr: 'Latitude',
          human_name_en: 'Latitude',
          type: 'Float',
        },
        {
          id: '018340bd-5dfc-708f-bdc6-dd4afdfa275e',
          human_name_fr: 'Longitude',
          human_name_en: 'Longitude',
          type: 'Float',
        },
        {
          id: '018340bd-608b-706b-ba6f-d92a37cbe365',
          human_name_fr: 'Libellé',
          human_name_en: 'Tag',
          name: 'tag',
          type: 'Enum',
          values_attributes: [
            {
              id: '018340bd-62f7-733e-a738-01f0c7761e33',
              human_name_fr: 'Domicile',
              human_name_en: 'Home',
            },
            {
              id: '018340bd-6597-7054-8e60-f66aca2a6fb6',
              human_name_fr: 'Bureau',
              human_name_en: 'Office',
            },
            {
              id: '018340be-4c6e-7203-9ca5-86d4c15fdd2d',
              human_name_fr: 'Autre',
              human_name_en: 'Other',
            },
          ]
        },
      ],
      associations_attributes: [
        {
          id: '0183413c-2c08-72b6-bdad-cc50178ec706',
          human_name_fr: 'propriétaire',
          human_name_en: 'owner',
          type: 'BelongsTo', # polymorphic
          }
      ],
    },
  ],
)

# TODO
# AccountContact
# JobExperience < AccountContact
# Training < AccountContact

puts 'finished'
