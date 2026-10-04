# frozen_string_literal: true

require 'uneek_sso_client/model/user_role/domain_context'

class UserRole
  class DomainContext < ApplicationRecord
    belongs_to :user_role, inverse_of: :domain_contexts, touch: true

    validates :user_role, :field_name, :value, presence: true
    validates :field_name, uniqueness: { scope: [:user_role_id] }

    include ::UneekSsoClient::Model::UserRole::DomainContext

    after_create :touch_manifest
    after_update :touch_manifest, if: :field_name_or_value_changed?
    after_destroy :touch_manifest

    def touch_manifest
      UneekPermission::Manifest.joins(community: [roles: [user_roles: :domain_contexts]]).where(community: {roles: {user_roles: {user_role_domain_contexts: {id: user_role_id}}}}).touch_all
    end

    def field_name_or_value_changed?
      self.field_name_changed? || self.value_changed?
    end

  end
end
