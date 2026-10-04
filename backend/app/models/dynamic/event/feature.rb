module Dynamic
  module Event
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Evènement',
          human_name_en: 'Event',
          mandatory: false,
          visible: true,
          enabled: false,
          concern_templates_attributes: [
            {
              name: 'Event',
              human_name_fr: 'Evènement',
              human_name_en: 'Event',
              template: true,
              options_attributes: [
                {
                  name: 'starting_date',
                  human_name_fr: 'Date de début',
                  human_name_en: 'Starting date',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'ending_date',
                  human_name_fr: 'Date de fin',
                  human_name_en: 'Ending date',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'cancelation_date',
                  human_name_fr: "Date d'annulation",
                  human_name_en: 'Cancelation date',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
              ],
            },
            {
              name: 'Indisponibility',
              human_name_fr: 'Indisponibilité',
              human_name_en: 'Indisponibility',
              template: true,
              options_attributes: [
                {
                  name: 'indisponibility_assoc',
                  human_name_fr: 'Association des indisponibilitées',
                  human_name_en: 'Indisponibility association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  value: ''
                },
                {
                  name: 'event_klass',
                  human_name_fr: "Table évènement ciblé par l'association",
                  human_name_en: 'Evant table targettted by association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::Klass',
                  value: ''
                },
              ],
            },
          ]
        }
      end

      def self.after_enabled(feature)
        feature.concerns.each do |c|
          case c.name
          when 'Event'
            unless c.klass
              c.errors.add(:klass, :missing)
              raise ActiveRecord::RecordInvalid.new(c)
            end
            create_date_attributes(c)
          when 'Indisponibility'
            unless c.klass
              c.errors.add(:klass, :missing)
              raise ActiveRecord::RecordInvalid.new(c)
            end
            create_indisponibilities_association(c)
          end
        end
      end

      def self.create_date_attributes(concern)
        klass = concern.klass
        starting_date_opt = concern.options.detect {|o| o.name == 'starting_date'}
        ending_date_opt = concern.options.detect {|o| o.name == 'ending_date'}
        cancelation_date_opt = concern.options.detect {|o| o.name == 'cancelation_date'}
        starting_date_attr = starting_date_opt&.value
        ending_date_attr = ending_date_opt&.value
        cancelation_date_attr = cancelation_date_opt&.value

        if starting_date_attr
          if starting_date_attr.type != 'DateTime'
            starting_date_opt.errors.add(:value, :invalid)
            raise ActiveRecord::RecordInvalid.new(concern)
          end
        else
          starting_date_attr = klass.attrs.create_with(
            human_name_fr: 'Date de début',
            human_name_en: 'Starting date',
            type: 'DateTime',
          ).find_or_create_by(name: 'starting_date')
          starting_date_opt.update!(value: starting_date_attr.id)
        end

        if ending_date_attr
          if ending_date_attr.type != 'DateTime'
            ending_date_opt.errors.add(:value, :invalid)
            raise ActiveRecord::RecordInvalid.new(concern)
          end
        else
          ending_date_attr = klass.attrs.create_with(
            human_name_fr: 'Date de fin',
            human_name_en: 'Ending date',
            type: 'DateTime',
          ).find_or_create_by(name: 'ending_date')
          ending_date_opt.update!(value: ending_date_attr.id)
        end


        if cancelation_date_attr
          if cancelation_date_attr.type != 'DateTime'
            cancelation_date_opt.errors.add(:value, :invalid)
            raise ActiveRecord::RecordInvalid.new(concern)
          end
        else
          cancelation_date_attr = klass.attrs.create_with(
            human_name_fr: "Date d'annulation",
            human_name_en: 'Cancelation date',
            type: 'DateTime',
          ).find_or_create_by(name: 'cancelation_date')
          cancelation_date_opt.update!(value: cancelation_date_attr.id)
        end

        klass.validations.create_with(
          type: 'Comparison::Attribute',
          operator: :less_than,
          comparison_attr_id: ending_date_attr.id,
          human_name_fr: 'Avant date de fin',
          human_name_en: 'Before ending date',
        ).find_or_create_by(
          attr_id: starting_date_attr.id,
          name: 'starting_date_less_than_ending_date'
        )

        klass.validations.create_with(
          type: 'Comparison::Attribute',
          operator: :greater_than,
          comparison_attr_id: starting_date_attr.id,
          human_name_fr: 'Après date de début',
          human_name_en: 'After starting date',
        ).find_or_create_by(
          attr_id: ending_date_attr.id,
          name: 'ending_date_greater_than_starting_date'
        )

        klass.validations.create_with(
          type: 'Comparison::Attribute',
          operator: :greater_than,
          comparison_attr_id: starting_date_attr.id,
          human_name_fr: 'Après date de début',
          human_name_en: 'After starting date',
        ).find_or_create_by(
          attr_id: cancelation_date_attr.id,
          name: 'cancelation_date_greater_than_starting_date'
        )

        klass.validations.create_with(
          type: 'Comparison::Attribute',
          operator: :less_than,
          comparison_attr_id: ending_date_attr.id,
          human_name_fr: 'Avant date de fin',
          human_name_en: 'Before ending date',
        ).find_or_create_by(
          attr_id: cancelation_date_attr.id,
          name: 'cancelation_date_less_than_ending_date'
        )
      end

      def self.create_indisponibilities_association(concern)
        klass = concern.klass
        indisponibility_assoc_opt = concern.options.detect {|o| o.name == 'indisponibility_assoc'}
        indisponibility_assoc = indisponibility_assoc_opt&.value
        event_target_klass_opt = concern.options.detect {|o| o.name == 'event_klass'}
        event_target_klass = event_target_klass_opt&.value

        event_target_klass_present_in_event_concern = concern.feature.concerns.detect {|c| c.name == 'Event' && c.klass_id == event_target_klass.id}
        unless event_target_klass_present_in_event_concern
          event_target_klass_opt.errors.add(:value, :invalid)
          raise ActiveRecord::RecordInvalid.new(concern)
        end

        if indisponibility_assoc
          if indisponibility_assoc.target_klass_id != event_target_klass.id || indisponibility_assoc.owner_klass_id != concern.klass_id
            indisponibility_assoc_opt.errors.add(:value, :invalid)
            raise ActiveRecord::RecordInvalid.new(concern)
          end
        else
          indisponibility_assoc = klass.associations.create_with(
            human_name_fr: 'Indisponibilités',
            human_name_en: 'Indisponibilities',
            type: 'HasMany',
            target_klass: event_target_klass
          ).find_or_create_by(name: 'indisponibilities')
          indisponibility_assoc_opt.update!(value: indisponibility_assoc.id)
        end
      end

    end
  end
end
