# frozen_string_literal: true

class CreateOptionsForCommunicationFeature < ActiveRecord::Migration[8.0]

  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
      next unless feature&.enabled

      contact_klass = schema.klasses.detect {|k| k.name == 'Contact'}
      account_klass = schema.klasses.detect {|k| ['Account', 'Entite', 'Organisation', 'Organization', 'Compte'].include?(k.name) }
      raise 'Account klass not found' unless account_klass
      feature.options.create!(
        [
          {
            name: 'contact_klass',
            human_name_fr: 'Table des contact',
            human_name_en: 'Contact Table',
            type: 'String',
            coder_type: 'Dynamic::Schema::Option::Coder::Klass',
            value: contact_klass
          },
          {
            name: 'account_klass',
            human_name_fr: 'Table des compte',
            human_name_en: 'Account Table',
            type: 'String',
            coder_type: 'Dynamic::Schema::Option::Coder::Klass',
            value: account_klass
          },
        ]
      )

      email_opt = feature.options.detect {|o| o.name == 'email_klass_name'}
      if email_opt
        email_klass = schema.klasses.detect {|k| k.name == email_opt.value}
        concern = feature.concerns.create!(
          name: 'Email',
          human_name_fr: 'Email',
          human_name_en: 'Email',
          klass: email_klass
        )

        feature_attrs = Dynamic::Communication::Feature.feature_attributes

        feature_attrs.dig(:concerns_attributes, 0, :options_attributes).each do |attrs|
          value = if attrs[:name].end_with?('_attribute')
            email_klass&.attrs&.detect {|a| a.name == attrs[:name]}
          elsif attrs[:name].start_with?('contact')
            contact_klass.associations.detect {|a| a.name == 'emails'}
          elsif attrs[:name].start_with?('account')
            account_klass.associations.detect {|a| a.name == 'emails'}
          end
          concern.options.create!(attrs.merge(value: value))
        end

        email_opt.destroy!
      end

      phone_opt = feature.options.detect {|o| o.name == 'phone_klass_name'}
      if phone_opt
        phone_klass = schema.klasses.detect {|k| k.name == phone_opt.value}
        concern = feature.concerns.create!(
          name: 'Phone',
          human_name_fr: 'Téléphone',
          human_name_en: 'Phone',
          klass: phone_klass,
        )

        feature_attrs.dig(:concerns_attributes, 1, :options_attributes).each do |attrs|
          value = if attrs[:name].end_with?('_attribute')
            phone_klass&.attrs&.detect {|a| a.name == attrs[:name]}
          elsif attrs[:name].start_with?('contact')
            contact_klass.associations.detect {|a| a.name == 'phones'}
          elsif attrs[:name].start_with?('account')
            account_klass.associations.detect {|a| a.name == 'phones'}
          end
          concern.options.create!(attrs.merge(value: value))
        end

        phone_opt.destroy!
      end

      address_opt = feature.options.detect {|o| o.name == 'address_klass_name'}
      if address_opt
        address_klass = schema.klasses.detect {|k| k.name == address_opt.value}
        concern = feature.concerns.create!(
          name: 'Address',
          human_name_fr: 'Adresse',
          human_name_en: 'Address',
          klass: address_klass,
        )

        feature_attrs.dig(:concerns_attributes, 2, :options_attributes).each do |attrs|
          value = if attrs[:name].end_with?('_attribute')
            address_klass&.attrs&.detect {|a| a.name == attrs[:name]}
          elsif attrs[:name].start_with?('contact')
            contact_klass.associations.detect {|a| a.name == 'addresses'}
          elsif attrs[:name].start_with?('account')
            account_klass.associations.detect {|a| a.name == 'addresses'}
          end
          concern.options.create!(attrs.merge(value: value))
        end

        address_opt.destroy!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
