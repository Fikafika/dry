# frozen_string_literal: true

class AddManifestToCommunities < ActiveRecord::Migration[8.0]
  def up
    Community.find_each do |community|
      existing_manifest = UneekPermission::Manifest.find_by(name: community.name)
      unless existing_manifest
        community.manifest = UneekPermission::Manifest.create!(name: community.name)
        community.save!
      end
      UneekPermission::Rule.where(schema_id: community.schema_id).update_all(manifest_id: community.manifest.id)
    end
    UneekPermission::Rule.where(schema_id: nil).find_each do |r|
      if r.instance
        case r.instance_type
        when 'Dynamic::Form', 'Dynamic::Import::Setting'
          community = Community.find_by(schema_id: r.instance.schema_id)
          r.update!(schema_id: r.instance.schema_id, manifest_id: community.manifest.id)
          next
        end
      end

      if r.receiver_type == 'Role'
        receiver = r.receiver
        if receiver
          community = receiver.community
          r.update!(schema_id: community.schema_id, manifest_id: community.manifest.id)
        else
          r.destroy!
        end
        next
      end

      if r.receiver_type == 'UneekPermission::PredefinedReceiver::Public'
        schema_name = r.klass_name.split('::')[1]
        community = Community.includes(:schema).where(schema: {name: schema_name}).first
        if community
          r.update!(schema_id: community.schema_id, manifest_id: community.manifest.id)
          next
        end
      end

      p "Cannot assign manifest to rule #{r.id} with klass_name #{r.klass_name} | instance #{r.instance_type} - #{r.instance_id} | receiver #{r.receiver_type} - #{r.receiver_id}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
