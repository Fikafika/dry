# frozen_string_literal: true

class AddSentAtToMessageKlassForMailhostingFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Message'}
      option = concern.options.detect {|o| o.name == 'sent_at_attribute'}
      attr = concern.klass.attrs.detect {|a| a.name == 'sent_at'}

      unless attr
        attr = concern.klass.attrs.create!(
          name: 'sent_at',
          type: 'DateTime',
          human_name_fr: 'Date',
          human_name_en: 'Date'
        )
      end

      unless option
        concern.options.create!(
          name: 'sent_at_attribute',
          human_name_fr: 'Attribut du contenu',
          human_name_en: 'Content attribute',
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
          value: attr.id,
          global: false,
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
