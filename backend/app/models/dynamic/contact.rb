module Dynamic
  module Contact

    module Feature
      extend ::Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Contact',
          human_name_en: 'Contact',
          mandatory: false,
          enabled: false,
          options_attributes: [
            {
              name: 'fill_not_in_form_fields',
              human_name_en: 'Fill not in form fields',
              human_name_fr: 'Remplir les champs hors des formulaires',
              type: 'Boolean',
              value: true
            }
          ],
          concern_templates_attributes: [
            name: 'MappingUneekMail',
            human_name_fr: 'Mapping des informations de contact depuis les mails',
            human_name_en: 'Contact information mapping from mail',
            template: true,
            options_attributes: [
              {
                name: 'nom',
                human_name_en: 'Last name',
                human_name_fr: 'Nom',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'prenom',
                human_name_en: 'First name',
                human_name_fr: 'Prénom',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'adresse',
                human_name_en: 'Address',
                human_name_fr: 'Adresse',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'email',
                human_name_en: 'Email',
                human_name_fr: 'Email',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'telephone',
                human_name_en: 'Phone',
                human_name_fr: 'Téléphone',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'fonction',
                human_name_en: 'Job title',
                human_name_fr: 'Fonction',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'entreprise',
                human_name_en: 'Company',
                human_name_fr: 'Raison sociale',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::Path',
                global: false,
              },
              {
                name: 'edit_contact_form_id',
                human_name_en: 'Edit contact form ID',
                human_name_fr: 'ID du formulaire de modification du contact',
                type: 'String',
                value: '',
              },
              {
                name: 'add_contact_form_id',
                human_name_en: 'Add contact form ID',
                human_name_fr: "ID du formulaire d'ajout du contact",
                type: 'String',
                value: '',
              }
            ]
          ]
        }
      end

      module MappingUneekMail
      end
    end
  end
end