# frozen_string_literal: true

class AddTrackingPixelToRecipientInfos < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}

      if feature&.enabled
        concern = feature.concerns.detect {|c| c.name == 'Email'}
        option = concern.options.detect {|o| o.name == 'consent_attribute'}
        option.update!(name: 'global_consent_attribute') if option

        global_attr = concern.klass.attrs.detect {|a| a.name == 'consent'}
        if global_attr
          global_attr.update!(
            name: 'global_consent',
            human_name_fr: 'Consentement global',
            human_name_en: 'Global Consent',
            locked: true,
          )
        end

        tracking_pixel_attr = concern.klass.attrs.create_with(
          human_name_fr: 'Consentement pixel de suivi',
          human_name_en: 'Tracking pixel consent',
          type: 'Boolean',
          locked: true,
        ).find_or_create_by!(name: 'tracking_pixel_consent')

        concern.options.create_with(
          human_name_fr: 'Attribut du consentement de pixel de suivi',
          human_name_en: 'Tracking pixel consent attribute',
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
          value: tracking_pixel_attr
        ).find_or_create_by!(name: 'tracking_pixel_consent_attribute')
      end


      feature = schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      if feature&.enabled
        concern = feature.concerns.detect {|c| c.name == 'Base'}
        global_attr = concern.klass.attrs.detect {|a| a.name == 'consent'}

        if global_attr
          global_attr.update!(
            name: 'global_consent',
            human_name_fr: 'Consentement global',
            human_name_en: 'Global consent',
          )
        end

        concern.klass.attrs.create_with(
          human_name_fr: 'Consentement pixel de suivi',
          human_name_en: 'Tracking pixel consent',
          type: 'Boolean',
        ).find_or_create_by!(name: 'tracking_pixel_consent')
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
