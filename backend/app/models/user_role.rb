# frozen_string_literal: true

require 'uneek_sso_client/model/user_role'

class UserRole < ApplicationRecord
  belongs_to :user, inverse_of: :user_roles
  belongs_to :role, inverse_of: :user_roles

  has_many :domain_contexts, :class_name => '::UserRole::DomainContext', :inverse_of => :user_role, :dependent => :destroy

  validates :role_id, uniqueness: { scope: [:user_id] }

  include ::UneekSsoClient::Model::UserRole
  include ::UneekPermission::UserRole
  include ::Dynamic::Permission::OpenSearch::UserRole

  after_create :touch_manifest
  after_destroy :touch_manifest

  def touch_manifest
    UneekPermission::Manifest.joins(community: [:roles]).where(roles: {id: role_id}).touch_all
  end
end
