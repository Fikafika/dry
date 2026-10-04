# frozen_string_literal: true

class AddScheduleConcernsForTransactionFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      unless feature.options.detect {|o| o.name == 'transaction_line_form_id'}
        feature.options.create!(
          name: 'transaction_line_form_id',
          type: 'Boolean',
          visible: false,
          value: false
        )
      end

      next if feature.concerns.detect {|c| c.name == 'InvoiceSchedule'}

      feature.concerns.create!(
        [
          {
            name: 'InvoiceSchedule',
            human_name_fr: 'Echéancier de facturation',
            human_name_en: 'Invoice schedule',
          },
          {
            name: 'InvoiceDueDate',
            human_name_fr: 'Echéance de facturation',
            human_name_en: 'Invoice due date',
            options_attributes: [
              {
                name: 'begin_attribute',
                human_name_fr: 'Attribut date de début',
                human_name_en: 'Start date attribute',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                global: false,
                value: ''
              },
              {
                name: 'validity_attribute',
                human_name_fr: 'Attribut validité',
                human_name_en: 'Validity attribute',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                global: false,
                value: ''
              },
              {
                name: 'invoice_association',
                human_name_fr: 'Association facture',
                human_name_en: 'Invoice association',
                type: 'String',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                global: false,
                value: ''
              },
              {
                name: 'in_future_enum_value_id',
                type: 'String',
                value: '',
                visible: false,
              },
              {
                name: 'ongoing_enum_value_id',
                type: 'String',
                value: '',
                visible: false,
              },
              {
                name: 'past_enum_value_id',
                type: 'String',
                value: '',
                visible: false,
              },
            ]
          },
        ]
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
