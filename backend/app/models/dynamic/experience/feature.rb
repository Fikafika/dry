module Dynamic
  module Experience
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Expérience',
          human_name_en: 'Experience',
          mandatory: false,
          visible: true,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Experience',
              human_name_fr: 'Expérience',
              human_name_en: 'Experience',
              options_attributes: [
                {
                  name: 'title_attribute',
                  human_name_fr: 'Attribut titre',
                  human_name_en: 'Title attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'start_date_attribute',
                  human_name_fr: "Attribut date début",
                  human_name_en: 'Start date attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'end_date_attribute',
                  human_name_fr: "Attribut date fin",
                  human_name_en: 'End date attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'main_organization_attribute',
                  human_name_fr: 'Attribut organisation principal',
                  human_name_en: 'Main organization attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'main_contact_attribute',
                  human_name_fr: 'Attribut contact principal',
                  human_name_en: 'Main contact attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'ongoing_attribute',
                  human_name_fr: 'Attribut en cours',
                  human_name_en: 'Ongoing attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'description_attribute',
                  human_name_fr: 'Attribut description',
                  human_name_en: 'Description attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'summary_attribute',
                  human_name_fr: 'Attribut résumé',
                  human_name_en: 'Summary attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'finish_previous_attribute',
                  human_name_fr: 'Attribut terminer précédente',
                  human_name_en: 'Finish previous attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'organization_association',
                  human_name_fr: "Association vers l'organisation",
                  human_name_en: 'Organization association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'owner_association',
                  human_name_fr: 'Association vers le propriétaire',
                  human_name_en: 'Owner association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Job',
              human_name_fr: 'Experience professionnelle',
              human_name_en: 'Professional experience',
              options_attributes: [
                {
                  name: 'activate',
                  human_name_fr: 'Créer La table',
                  human_name_en: 'Create table',
                  type: 'Boolean',
                  value: true
                },
                {
                  name: 'synchronize',
                  human_name_fr: "Synchonisation de l'expérience principale vers son propriétaire",
                  human_name_en: 'Synchronize main experience with its owner',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'finish_previous',
                  human_name_fr: "Clôture de l'expérience en cours",
                  human_name_en: 'Terminate ongoing experience',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'members_association',
                  human_name_fr: 'Association entre compte et fonctions',
                  human_name_en: 'Association between account and job experiences',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'function_attribute',
                  human_name_fr: 'Attribut fonction du contact',
                  human_name_en: 'Contact function attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'experiences_association',
                  human_name_fr: 'Association entre contact et fonctions',
                  human_name_en: 'Association between contact and job experiences',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'organization_association',
                  human_name_fr: 'Association entre contact et compte',
                  human_name_en: 'Association between contact and account',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Training',
              human_name_fr: 'Formation',
              human_name_en: 'Training',
              options_attributes: [
                {
                  name: 'activate',
                  human_name_fr: 'Créer La table',
                  human_name_en: 'Create table',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'synchronize',
                  human_name_fr: "Synchonisation de l'expérience principale vers son propriétaire",
                  human_name_en: 'Synchronize main experience with its owner',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'finish_previous',
                  human_name_fr: "Clôture de l'expérience en cours",
                  human_name_en: 'Terminate ongoing experience',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'members_association',
                  human_name_fr: 'Association entre école et formations',
                  human_name_en: 'Association between school and trainings',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'function_attribute',
                  human_name_fr: 'Attribut fonction du contact',
                  human_name_en: 'Contact function attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'experiences_association',
                  human_name_fr: 'Association entre édudiant et formations',
                  human_name_en: 'Association between student and trainings',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'organization_association',
                  human_name_fr: 'Association entre étudiant et école',
                  human_name_en: 'Association between student and school',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
            {
              name: 'Volunteering',
              human_name_fr: 'Bénévolat',
              human_name_en: 'Volunteering',
              options_attributes: [
                {
                  name: 'activate',
                  human_name_fr: 'Créer La table',
                  human_name_en: 'Create table',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'synchronize',
                  human_name_fr: "Synchonisation de l'expérience principale vers son propriétaire",
                  human_name_en: 'Synchronize main experience with its owner',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'finish_previous',
                  human_name_fr: "Clôture de l'expérience en cours",
                  human_name_en: 'Terminate ongoing experience',
                  type: 'Boolean',
                  value: false
                },
                {
                  name: 'members_association',
                  human_name_fr: 'Association entre organisation et bénévolats',
                  human_name_en: 'Association between organization and volunteerings',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'function_attribute',
                  human_name_fr: 'Attribut fonction du bénévole',
                  human_name_en: 'Volunteer function attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'experiences_association',
                  human_name_fr: 'Association entre bénévole et bénévolats',
                  human_name_en: 'Association between volunteer and volunteerings',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'organization_association',
                  human_name_fr: 'Association entre bénévole et organisation',
                  human_name_en: 'Association between volunteer and organization',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ]
            },
          ],
          options_attributes: [
            {
              name: 'owner_klass',
              human_name_fr: 'Table du propriétaire',
              human_name_en: "Owner's table",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: ''
            },
            {
              name: 'organization_klass',
              human_name_fr: 'Table du compte',
              human_name_en: "Account's table",
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: ''
            },
            {
              name: 'update_forms_after_enable',
              human_name_fr: 'Mettre à jour les formulaires',
              human_name_en: 'Update forms',
              type: 'Boolean',
              value: true
            },
          ]
        }
      end

      def self.after_enabled(feature)
        opt_owner = feature.options.detect {|o| o.name == 'owner_klass'}
        owner_klass = opt_owner.value
        opt_organization = feature.options.detect {|o| o.name == 'organization_klass'}
        organization_klass = opt_organization.value
        unless owner_klass
          opt_owner.errors.add :enabled, :missing
        end
        unless organization_klass
          opt_organization.errors.add :enabled, :missing
        end
        unless owner_klass && organization_klass
          raise ActiveRecord::RecordInvalid.new(feature)
        end

        concern_experience = feature.concerns.detect {|o| o.name == 'Experience'}
        concern_experience.update!(klass: create_experience_klass(feature.schema)) unless concern_experience.klass
        self.map_experience_attributes(concern_experience)
        owner_experience_assoc, organization_experience_assoc = self.map_experience_associations(concern_experience, owner_klass, organization_klass)

        self.map_experience_subtype_concern(feature, concern_experience.klass, 'Job', owner_experience_assoc, organization_experience_assoc)
        self.map_experience_subtype_concern(feature, concern_experience.klass, 'Training', owner_experience_assoc, organization_experience_assoc)
        self.map_experience_subtype_concern(feature, concern_experience.klass, 'Volunteering', owner_experience_assoc, organization_experience_assoc)
      end

      def self.after_enabled_and_commit_schema(feature)
        exp_concern = feature.concerns.detect {|c| c.name == 'Experience'}
        exp_klass = exp_concern.klass

        unless exp_klass.name_attribute_id
          exp_klass.update!(name_attribute_id: exp_concern.options.detect {|o| o.name == 'title_attribute'}&.value_string)
        end

        update_form_option = feature.options.detect {|o| o.name == 'update_forms_after_enable'}
        return unless update_form_option.value
        update_form_option.update!(value: false)
        feature.schema.load
        self.update_forms(feature, exp_klass)
      end

      private

      def self.map_experience_associations(concern_experience, owner_klass, organization_klass)
        owner_experience_assoc = owner_klass.associations.create_with(
          human_name_fr: 'Expériences',
          human_name_en: 'Experiences',
        ).find_or_create_by!(
          type: 'HasMany',
          name: 'experiences',
          target_klass: concern_experience.klass
        )
        organization_experience_assoc = organization_klass.associations.create_with(
          human_name_fr: 'Membres',
          human_name_en: 'Members',
        ).find_or_create_by!(
          type: 'HasMany',
          name: 'members',
          target_klass: concern_experience.klass
        )
        r = self.assign_options_values(concern_experience,
          [
            {
              type: 'Assoc',
              option_name: 'organization_association',
              mandatory_attributes: {
                name: 'organization',
                type: 'BelongsTo',
                target_klass: organization_klass,
                inverse_of: organization_experience_assoc,
              },
              optional_attributes: {
                human_name_fr: 'Organisation',
                human_name_en: 'Organization',
              }
            },
            {
              type: 'Assoc',
              option_name: 'owner_association',
              mandatory_attributes: {
                name: 'owner',
                type: 'BelongsTo',
                target_klass: owner_klass,
                inverse_of: owner_experience_assoc,
              },
              optional_attributes: {
                human_name_fr: 'Propriétaire',
                human_name_en: 'Owner',
              }
            },
          ]
        )
        experience_organization_assoc = r.detect {|a| a.name == 'organization'}
        experience_owner_assoc = r.detect {|a| a.name == 'owner'}
        organization_experience_assoc.update!(inverse_of: experience_organization_assoc)
        owner_experience_assoc.update!(inverse_of: experience_owner_assoc)
        return owner_experience_assoc, organization_experience_assoc
      end

      def self.map_experience_subtype_concern(feature, experience_klass, subtype_concern_name, owner_assoc, organization_assoc)
        subtype_concerns = feature.concerns.select {|c| c.name == subtype_concern_name}
        raise_incomplete_concern_error(subtype_concerns.last) if subtype_concerns.length > 1
        subtype_concern = subtype_concerns.first
        return unless subtype_concern.options.detect {|o| o.name == 'activate'}.value == true

        organization_klass = feature.options.detect {|o| o.name == 'organization_klass'}.value
        owner_klass = feature.options.detect {|o| o.name == 'owner_klass'}.value

        owner_already_synchronizing = feature.concerns.select do |c|
          c.name.in?(['Job', 'Training', 'Volunteering']) && c.klass_id == owner_klass.id
        end.any? {|c| c.options.detect {|o| o.name == 'synchronize'}&.value}
        raise_incomplete_concern_error(subtype_concern) unless organization_klass && owner_klass && !owner_already_synchronizing

        unless feature.concerns.detect {|c| c.name == 'Owner' && c.klass_id == owner_klass.id}
          feature.concerns.create_with(
            human_name_fr: 'Propriétaire',
            human_name_en: 'Owner',
          ).find_or_create_by!(
            klass: owner_klass,
            name: 'Owner',
          )
        end

        case subtype_concern_name
        when 'Job'
          self.map_job_experience_concern(subtype_concern, experience_klass, owner_assoc, organization_assoc)
        when 'Training'
          self.map_training_concern(subtype_concern, experience_klass, owner_assoc, organization_assoc)
        when 'Volunteering'
          self.map_volunteering_concern(subtype_concern, experience_klass, owner_assoc, organization_assoc)
        end

        sync = subtype_concern.options.detect {|o| o.name == 'synchronize'}&.value
        self.map_owner_attributes(subtype_concern) if sync
      end

      def self.map_job_experience_concern(job_concern, experience_klass, owner_assoc, organization_assoc)
        unless job_concern.klass
          job_concern.update!(klass: self.create_job_experience_klass(job_concern.schema, experience_klass))
        end
        job_experience_klass = job_concern.klass

        self.map_owner_associations(
          job_concern,
          {human_name_fr: 'Expériences professionnelles', human_name_en: 'Professional experiences', name: 'professional_experiences', through_id: owner_assoc.id},
          {human_name_fr: 'Organisation principale', human_name_en: 'Main organization', name: 'organization'},
        )
        self.map_organization_associations(
          job_concern,
          {human_name_fr: 'Collaborateurs', human_name_en: 'Collaborators', name: 'collaborators', through_id: organization_assoc.id},
          job_experience_klass
        )
      end

      def self.create_job_experience_klass(schema, experience_klass)
        return schema.klasses.create!(
          name: 'JobExperience',
          human_name_fr: 'Expérience Professionnelle',
          human_name_en: 'Job Experience',
          plural_human_name_fr: 'Expériences Professionnelle',
          plural_human_name_en: 'Job Experiences',
          superklass: experience_klass,
          icon: 'user-tie',
        )
      end

      def self.map_training_concern(training_concern, experience_klass, owner_assoc, organization_assoc)
        unless training_concern.klass
          training_concern.update!(klass: self.create_training_klass(training_concern.schema, experience_klass))
        end
        training_klass = training_concern.klass

        self.map_owner_associations(
          training_concern,
          {human_name_fr: 'Formations', human_name_en: 'Trainings', name: 'trainings', through_id: owner_assoc.id},
          {human_name_fr: 'Ecole', human_name_en: 'School', name: 'school'},
        )
        self.map_organization_associations(
          training_concern,
          {human_name_fr: 'Etudiants', human_name_en: 'Students', name: 'students', through_id: organization_assoc.id},
          training_klass
        )
      end

      def self.create_training_klass(schema, experience_klass)
        return schema.klasses.create!(
          name: 'Training',
          human_name_fr: 'Formation',
          human_name_en: 'Training',
          plural_human_name_fr: 'Formations',
          plural_human_name_en: 'Trainings',
          superklass: experience_klass,
          icon: 'user-graduate',
        )
      end

      def self.map_volunteering_concern(volunteering_concern, experience_klass, owner_assoc, organization_assoc)
        unless volunteering_concern.klass
          volunteering_concern.update!(klass: self.create_volunteering_klass(volunteering_concern.schema, experience_klass))
        end
        volunteering_klass = volunteering_concern.klass

        self.map_owner_associations(
          volunteering_concern,
          {human_name_fr: 'Bénévolats', human_name_en: 'Volunteerings', name: 'volunteerings', through_id: owner_assoc.id},
          {human_name_fr: 'Organisation principale', human_name_en: 'Main organization', name: 'volunteering_organization'},
        )
        self.map_organization_associations(
          volunteering_concern,
          {human_name_fr: 'Bénévoles', human_name_en: 'Volunteers', name: 'volunteers', through_id: organization_assoc.id},
          volunteering_klass
        )
      end

      def self.create_volunteering_klass(schema, experience_klass)
        return schema.klasses.create!(
          name: 'Volunteering',
          human_name_fr: 'Bénévolat',
          human_name_en: 'Volunteering',
          plural_human_name_fr: 'Bénévolats',
          plural_human_name_en: 'Volunteerings',
          superklass: experience_klass,
          icon: 'praying-hands',
        )
      end

      def self.map_owner_attributes(concern)
        opt = concern.options.detect {|o| o.name == 'function_attribute'}
        return if opt.value

        owner_klass = concern.feature.options.detect {|o| o.name == 'owner_klass'}.value
        old_owner_klass = concern.schema.klasses.detect {|k| k.id == owner_klass.id} # owner_klass has a different schema than concern
        r = old_owner_klass.attrs.create_with(
          human_name_fr: 'Fonction',
          human_name_en: 'Job experience',
        ).find_or_create_by!(
          name: 'function',
          type: 'String',
        )

        opt.update!(value: r)
      end

      def self.map_owner_associations(concern, exp_assoc_attrs, org_assoc_attrs)
        organization_klass = concern.feature.options.detect {|o| o.name == 'organization_klass'}.value
        owner_klass = concern.feature.options.detect {|o| o.name == 'owner_klass'}.value
        old_owner_klass = concern.schema.klasses.detect {|k| k.id == owner_klass.id} # owner_klass has a different schema than concern

        option = concern.options.detect {|o| o.name == 'experiences_association'}

        unless option.value
          r = old_owner_klass.associations.create_with(
            human_name_fr: exp_assoc_attrs[:human_name_fr],
            human_name_en: exp_assoc_attrs[:human_name_en],
          ).find_or_create_by!(
            name: exp_assoc_attrs[:name],
            type: 'HasMany',
            target_klass: concern.klass,
            through_id: exp_assoc_attrs[:through_id],
          )

          option.update!(value: r)
        end

        return unless concern.options.detect {|o| o.name == 'synchronize'}&.value

        option = concern.options.detect {|o| o.name == 'organization_association'}
        unless option.value
          r = old_owner_klass.associations.create_with(
            human_name_fr: org_assoc_attrs[:human_name_fr],
            human_name_en: org_assoc_attrs[:human_name_end],
          ).find_or_create_by!(
            name: org_assoc_attrs[:name],
            type: 'BelongsTo',
            target_klass: organization_klass,
          )

          option.update!(value: r)
        end
      end

      def self.map_organization_associations(concern, assoc_attrs, experience_klass)
        organization_klass = concern.feature.options.detect {|o| o.name == 'organization_klass'}.value
        member_opt = concern.options.detect {|o| o.name == 'members_association'}
        return if member_opt.value

        old_organization_klass = concern.schema.klasses.detect {|k| k.id == organization_klass.id} # organization_klass has a different schema than concern
        r = old_organization_klass.associations.create_with(
          human_name_fr: assoc_attrs[:human_name_fr],
          human_name_en: assoc_attrs[:human_name_en],
        ).find_or_create_by!(
          name: assoc_attrs[:name],
          type: 'HasMany',
          target_klass: experience_klass,
          through_id: assoc_attrs[:through_id],
        )

        member_opt.update!(value: r)
      end

      def self.create_experience_klass(schema)
        return schema.klasses.create_with(
          human_name_fr: 'Experience',
          human_name_en: 'Experience',
          plural_human_name_fr: 'Experiences',
          plural_human_name_en: 'Experiences',
          table_profile: :medium,
          icon: 'hiking',
          update_menu_items: false,
        ).find_or_create_by!(name: 'Experience')
      end

      def self.map_experience_attributes(concern)
        assign_options_values(concern,
          [
            {
              type: 'Attr',
              option_name: 'start_date_attribute',
              mandatory_attributes: {
                name: 'start_date',
                type: 'Date',
              },
              optional_attributes: {
                human_name_fr: 'Date de début',
                human_name_en: 'Start date',
              }
            },
            {
              type: 'Attr',
              option_name: 'end_date_attribute',
              mandatory_attributes: {
                name: 'end_date',
                type: 'Date',
              },
              optional_attributes: {
                human_name_fr: 'Date de fin',
                human_name_en: 'End date',
              }
            },
            {
              type: 'Attr',
              option_name: 'main_organization_attribute',
              mandatory_attributes: {
                name: 'main_organization',
                type: 'Boolean',
              },
              optional_attributes: {
                human_name_fr: 'Entité principal',
                human_name_en: 'Main organization',
              }
            },
            {
              type: 'Attr',
              option_name: 'main_contact_attribute',
              mandatory_attributes: {
                name: 'main_contact',
                type: 'Boolean',
              },
              optional_attributes: {
                human_name_fr: 'Contact principal',
                human_name_en: 'Main contact',
              }
            },
            {
              type: 'Attr',
              option_name: 'ongoing_attribute',
              mandatory_attributes: {
                name: 'ongoing',
                type: 'Boolean',
              },
              optional_attributes: {
                human_name_fr: 'En cours',
                human_name_en: 'Ongoing',
              }
            },
            {
              type: 'Attr',
              option_name: 'title_attribute',
              mandatory_attributes: {
                name: 'title',
                type: 'String',
              },
              optional_attributes: {
                human_name_fr: 'Titre',
                human_name_en: 'Title',
              }
            },
            {
              type: 'Attr',
              option_name: 'description_attribute',
              mandatory_attributes: {
                name: 'description',
                type: 'Text',
              },
              optional_attributes: {
                human_name_fr: 'Description',
                human_name_en: 'Description',
              }
            },
            {
              type: 'Attr',
              option_name: 'summary_attribute',
              mandatory_attributes: {
                name: 'summary',
                type: 'Text',
              },
              optional_attributes: {
                human_name_fr: 'Résumé',
                human_name_en: 'Summary',
              }
            },
            {
              type: 'Attr',
              option_name: 'finish_previous_attribute',
              mandatory_attributes: {
                name: 'finish_previous',
                type: 'Boolean',
              },
              optional_attributes: {
                human_name_fr: 'Terminer experience précédente',
                human_name_en: 'Close previous experience',
              }
            },
          ]
        )
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

          if param[:type] == 'Assoc'
            method_name = 'associations'
          elsif param[:type] == 'Attr'
            method_name = 'attrs'
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

      def self.update_forms(feature, experience_klass)
        schema = feature.schema
        experience_concern = feature.concerns.detect {|c| c.name == 'Experience'}

        ongoing_option = experience_concern.options.detect {|o| o.name == 'ongoing_attribute'}
        finish_previous_option = experience_concern.options.detect {|o| o.name == 'finish_previous_attribute'}

        experience_klass = schema.klasses.detect {|k| k.id == experience_concern.klass_id}
        experience_klass.attrs.reload

        sub_experience_concerns = feature.concerns.select {|c| c.name.in?(['Job', 'Training', 'Volunteering'])}
        sub_experience_concerns.each do |c|
          next unless c.klass
          if ongoing_option.value
            schema.forms.where(klass_name: c.klass.const_absolute_name, actions: 1).each do |form|
              form.elements.where(attribute_name: ongoing_option.value.name).each do |elem|
                elem.update!(default_value: 1)
              end
            end
          end

          if finish_previous_option.value
            schema.forms.where(klass_name: c.klass.const_absolute_name, actions: 1).each do |form|
              next if form.elements.detect {|e| e.type == 'Layout::Page'}
              first_page = form.elements.create!(type: 'Layout::Page', position: 0)
              second_page = form.elements.create!(type: 'Layout::Page', position: 1)
              form.elements.each do |elem|
                if elem.attribute_name == finish_previous_option.value.name
                  elem.update!(parent_id: second_page.id)
                elsif elem.type != 'Layout::Page'
                  elem.update!(parent_id: first_page.id)
                end
              end
            end
          end
        end
      end

      def self.raise_incomplete_concern_error(concern)
        concern.errors.add(:missing)
        raise ActiveRecord::RecordInvalid.new(concern)
      end

    end
  end
end
