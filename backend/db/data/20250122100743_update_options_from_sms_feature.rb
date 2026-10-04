# frozen_string_literal: true

class UpdateOptionsFromSmsFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Sms::Feature'}
      next unless feature

      option_phone_klass_name = feature.options.detect {|o| o.name == 'phone_klass_name'}
      next unless option_phone_klass_name
      phone_klass = schema.klasses.detect {|k| k.name == option_phone_klass_name.value}
      option_phone_klass_name&.update!(
        name: 'phone_klass',
        value: phone_klass&.id,
        coder_type: 'Dynamic::Schema::Option::Coder::Klass'
      )

      owner_association = phone_klass ? phone_klass.associations.detect {|a| a.target_klass.nil? && a.inverse_of.nil? && a.type == 'BelongsTo'} : nil
      phone_number_attr = phone_klass ? phone_klass.attrs.detect {|a| a.validations.detect {|v| v.type == 'Format::InternationalPhoneNumber'}} : nil

      feature.options.create_with(
        human_name_fr: 'Formule du numéro de téléphone',
        human_name_en: "Phone's number formula",
        type: 'String',
        value: phone_number_attr&.name
      ).find_or_create_by(name: 'phone_number_formula')
      feature.options.create_with(
        human_name_fr: 'Formule du propriétaire téléphone',
        human_name_en: "Phone's owner formula",
        type: 'String',
        value: owner_association&.name
      ).find_or_create_by(name: 'owner_formula')

      sms_klass = feature.concerns.detect {|c| c.name == 'Sms'}&.klass
      next unless sms_klass

      sms_klass_name = sms_klass.const_absolute_name
      sms_attrs_by_name = sms_klass.attrs.index_by(&:name).merge(sms_klass.associations.index_by(&:name))

      edit_form = Dynamic::Form.find_by(klass_name: sms_klass_name, actions: [2])

      edit_form.elements.each {|e| e.update!(disabled: true)} if edit_form

      common_form_attrs = {
        schema_id: schema.id,
        default: true,
        mode: 'input',
        klass_name: sms_klass_name,
        association_name: 'smses',
        source_klass_name: sms_klass_name,
      }

      sms_form = Dynamic::Form.find_by(
        common_form_attrs.merge(
          source_klass_name: nil,
          association_klass_name: nil,
          association_name: nil
        )
      )

      elements_to_make_mandatory = sms_form.elements.select {|e| e.attribute_name.in?(['sender', 'message', 'phone', 'owner'])}

      sms_form_through_phone = Dynamic::Form.find_by(
        common_form_attrs.merge(
          target_klass_name: phone_klass&.const_absolute_name,
          association_klass_name: phone_klass&.const_absolute_name,
        )
      )

      if sms_form_through_phone
        elements_to_make_mandatory += sms_form_through_phone.elements.select {|e| e.attribute_name.in?(['sender', 'message'])}

        sms_form_through_phone.elements.create!([
          sms_klass.dynamic_form_element_attrs(sms_attrs_by_name['phone_number']).merge(
            default_value_formula: phone_number_attr&.name,
            record_type_for_default_value_formula: :target_record,
            editor: :hidden,
          ),
          sms_klass.dynamic_form_element_attrs(sms_attrs_by_name['owner']).merge(
            default_value_formula: owner_association&.name,
            record_type_for_default_value_formula: :target_record,
            editor: :hidden,
          )
        ])
      end

      submit_all_action = Dynamic::Form::ACTIONS_TO_I[:submit_all]
      new_action = Dynamic::Form::ACTIONS_TO_I[:new]

      feature.concerns.select {|c| c.name == 'Owner'}.each do |o|
        next unless o.klass
        o.options.detect {|o| o.name == 'phone_formula_submit_all'}.update!(name: 'phone_formula')
        form_option = o.options.detect {|o| o.name == 'submit_all_form_name'}&.destroy

        o.options.create!(
          name: 'phone_number_formula',
          human_name_fr: "Formule des numéros de téléphones pour l'envoi multiple",
          human_name_en: "Phones' number formula for multiple sending",
          type: 'String',
          value: nil
        )

        owner_klass_name = o.klass.const_absolute_name

        common_form_attrs_for_owner = common_form_attrs.merge(
          target_klass_name: owner_klass_name,
          association_klass_name: owner_klass_name,
        )

        submit_all_form = Dynamic::Form.with_actions(submit_all_action).find_by(common_form_attrs_for_owner)

        if submit_all_form
          elements_to_make_mandatory += submit_all_form.elements.select {|e| e.attribute_name.in?(['sender', 'message'])}
          submit_all_form.elements.create!([
            sms_klass.dynamic_form_element_attrs(sms_attrs_by_name['phone_number']).merge(
              record_type_for_default_value_formula: :target_record,
              editor: :hidden,
            ),
            sms_klass.dynamic_form_element_attrs(sms_attrs_by_name['phone']).merge(
              record_type_for_default_value_formula: :target_record,
              editor: :hidden,
            )
          ])
        end

        new_sms_through_owner = Dynamic::Form.with_actions(new_action).find_by(common_form_attrs_for_owner)

        if new_sms_through_owner
          elements_to_make_mandatory += new_sms_through_owner.elements.select {|e| e.attribute_name.in?(['sender', 'message', 'phone'])}
          new_sms_through_owner.elements.create!(
            sms_klass.dynamic_form_element_attrs(sms_attrs_by_name['phone_number']).merge(
              record_type_for_default_value_formula: :target_record,
              editor: :hidden,
            ),
          )
        end

      end

      elements_to_make_mandatory.each do |e|
        e.update!(requirement: 'mandatory', skip_update_schema: true)
      end if elements_to_make_mandatory
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end