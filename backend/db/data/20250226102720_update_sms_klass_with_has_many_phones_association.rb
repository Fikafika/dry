# frozen_string_literal: true

class UpdateSmsKlassWithHasManyPhonesAssociation < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Sms::Feature'}
      next unless feature
      feature.options.create(
        [
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
        ]
      )

      sms_klass = schema.klasses.find_by(name: 'Sms')
      next unless sms_klass

      sms_concern = feature.concerns.detect {|c| c.name == 'Sms'}
      sms_concern.options.create(
        [
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
      )

      sms_base_forms = []

      [:input, :read_only, :edit_in_place].each do |mode|
        form = Dynamic::Form.find_by(default: true, mode: mode, klass_name: sms_klass.const_absolute_name, target_klass_name: nil)
        sms_base_forms << form if form
      end

      sms_base_forms.each do |f|
        phone_element = f.elements.detect {|e| e.attribute_name == 'phone'}
        owner_element = f.elements.detect {|e| e.attribute_name == 'owner'}
        if f.mode == :input
          phone_element&.update!(max: 1)
          owner_element&.update!(max: 1)
        end
        phone_element&.update_column(:type, 'Association::HasMany')
        owner_element&.update_column(:type, 'Association::HasMany')
      end

      sms_owner_forms = []
      feature.concerns.select {|c| c.name == 'Owner'}.each do |o|
        [:new, :submit_all].each do |action|
          a = Dynamic::Form.actions_to_db([action])
          form = Dynamic::Form.find_by(actions: a, association_name: 'smses', klass_name: sms_klass.const_absolute_name, target_klass_name: o.klass.const_absolute_name)
          sms_owner_forms << form if form
        end
        o.klass.associations.detect {|a| a.name == 'smses'}&.update!(inverse_of: nil)
        o.options.create!(
          name: 'owner_formula',
          human_name_fr: "Formule des propriétaires pour l'envoi multiple",
          human_name_en: "Phone's owner formula for multiple sending",
          type: 'String',
          value: ''
        )
      end

      sms_owner_forms.each do |f|
        element = f.elements.detect {|e| e.attribute_name == 'phone'}
        f.elements.create!(
          root_klass_name: sms_klass.const_absolute_name,
          klass_name: sms_klass.const_absolute_name,
          attribute_name: 'owners',
          type: 'Association::HasMany',
          default_value_formula: '',
          record_type_for_default_value_formula: :target_record,
          editor: :hidden,
        )
        next unless element
        new_attributes = {errors_from: ['phones']}
        new_attributes.merge!(max: 1) if f.mode == :input
        element.update!(new_attributes)
        element.update_column(:type, 'Association::HasMany')
      end

      sms_klass.associations.detect {|a| a.name == 'phone'}&.update!(type: 'HasMany')
      sms_klass.associations.detect {|a| a.name == 'owner'}&.update!(type: 'HasMany')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
