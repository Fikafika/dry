# frozen_string_literal: true

class ComputeBaseklassIdOnDynamicAssociationsAndAttachments < ActiveRecord::Migration[8.0]
  def up
    [
      Dynamic::Schema::Association::Base,
      Dynamic::Schema::Attachment::Base,
    ].each do |k|
      k.find_each do |a|
        next unless a.baseklass_id.nil?
        a.update_column(:baseklass_id, a.owner_klass.baseklass_id)
      end
    end
  end

  def down
  end
end
