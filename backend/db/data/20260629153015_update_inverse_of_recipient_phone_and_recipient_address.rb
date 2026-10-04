# frozen_string_literal: true

class UpdateInverseOfRecipientPhoneAndRecipientAddress < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      next unless feature&.enabled

      recipient_info_concern = feature.concerns.detect {|c| c.name == 'Base'}
      target_assoc = recipient_info_concern.klass.associations.detect {|a| a.name == 'target'}
      next unless target_assoc

      unique_phone_concern = feature.concerns.detect {|c| c.name == 'RecipientPhoneNumber'}
      if unique_phone_concern&.klass
        info_assoc = unique_phone_concern.klass.associations.detect {|a| a.name == 'info'}
        info_assoc.update!(inverse_of: target_assoc)
      else
        Rails.logger.warn {"Concern RecipientPhoneNumber : #{unique_phone_concern ? unique_phone_concern.id : "Missing" } does not have a klass"}
      end

      address_concern = feature.concerns.detect {|c| c.name == 'Address'}
      if address_concern&.klass
        info_assoc = address_concern.klass.associations.detect {|a| a.name == 'info'}
        info_assoc&.update!(inverse_of: target_assoc)
      else
        Rails.logger.warn {"Concern Address : #{address_concern ? address_concern.id : "Missing" } does not have a klass"}
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
