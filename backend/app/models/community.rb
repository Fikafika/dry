# frozen_string_literal: true

require 'uneek_sso_client/model/community'
require 'uneek_sso_client/model/sync/sidekiq'

class Community < ApplicationRecord

  belongs_to :parent, class_name: 'Community', inverse_of: :children, optional: true
  has_many :children, class_name: 'Community', inverse_of: :parent, foreign_key: :parent_id, dependent: :destroy

  has_many :tools, inverse_of: :community, dependent: :destroy
  has_many :roles, inverse_of: :community, dependent: :destroy

  has_many :memberships, inverse_of: :community, dependent: :destroy
  has_many :users, through: :memberships, inverse_of: :communities

  validates :name, :permalink, presence: true, uniqueness: true

  include ::UneekSsoClient::Model::Community
  include ::UneekSsoClient::Model::Sync::Sidekiq

  concerning :Dynamic do
    included do
      belongs_to :schema, class_name: 'Dynamic::Schema', optional: true

      before_create :before_create_dynamic_schema
      after_destroy :after_destroy_dynamic_schema
    end

    private

    def before_create_dynamic_schema
      unless self.schema_id
        begin
          self.create_schema!(name: self.permalink)
        rescue ActiveRecord::RecordInvalid => e
          if e.record.errors.first&.type == :taken
            existing = ::Dynamic::Schema.find_by(name: e.record.name)
            unless Community.where(schema_id: existing.id).exists?
              self.schema = existing
            else
              raise
            end
          else
            raise
          end
        end
      end
    end

    # TODO preload
    def after_destroy_dynamic_schema
      self.schema&.destroy
    end

    def schema_name # used by frontend in order to properly find community for current schema in url
      schema&.name
    end
  end

  concerning :Appearance do

    included do
      belongs_to :theme, class_name: 'Dynamic::Theme', optional: true

      after_save :update_community_appearance

      def update_community_appearance
        return unless theme_id_previously_changed? && schema
        if self.theme_id
          schema.themes.where.not(id: self.theme_id).update_all(community_appearance: false)
          schema.themes.where(id: self.theme_id).update_all(community_appearance: true)
        else
          schema.themes.update_all(community_appearance: false)
        end
      end
    end

  end

  concerning :Permissions do

    included do
      has_one :manifest, class_name: 'UneekPermission::Manifest', dependent: :destroy
      after_create :create_manifest
      after_destroy :destroy_manifest
    end

    private

    def create_manifest
      return if self.manifest
      begin
        self.create_manifest!(name: self.name)
      rescue ActiveRecord::RecordInvalid => e
        if e.record.errors.first&.type == :taken
          existing = ::UneekPermission::Manifest.find_by(name: e.record.name)
          if existing.community.nil?
            self.manifest = existing
          else
            raise
          end
        else
          raise
        end
      end
    end

    def destroy_manifest
      self.manifest&.destroy
    end

  end

end
