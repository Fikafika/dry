# frozen_string_literal: true

class AddDeliveryAndNameOptionsForCommunicationFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
      next unless feature

      concern = feature.concerns.detect {|c| c.name == 'Address'}
      if feature.enabled
        address_klass = concern.klass
        delivery_mention_attribute = address_klass&.attrs&.detect {|a| a.name == 'delivery_mention'}
        second_delivery_mention_attribute = address_klass&.attrs&.detect {|a| a.name == 'second_delivery_mention'}
        name_attribute = address_klass&.attrs&.detect {|a| a.name == 'name'}
      end

      concern.options.create_with(
        human_name_fr: 'Attribut de la mention de livraison',
        human_name_en: 'Delivery mention attribute',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: delivery_mention_attribute
      ).find_or_create_by!(name: 'delivery_mention_attribute')

      concern.options.create_with(
        human_name_fr: 'Attribut de la seconde mention de livraison',
        human_name_en: 'Second delivery mention attribute',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: second_delivery_mention_attribute
      ).find_or_create_by!(name: 'second_delivery_mention_attribute')

      concern.options.create_with(
        human_name_fr: "Attribut du nom de l'objet",
        human_name_en: 'Object name attribute',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: name_attribute
      ).find_or_create_by!(name: 'name_attribute')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
