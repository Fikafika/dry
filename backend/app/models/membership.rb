# frozen_string_literal: true

require 'uneek_sso_client/model/membership'
require 'uneek_sso_client/model/sync/sidekiq'

class Membership < ApplicationRecord

  enum :status, { active: 0, inactive: 1, pending: 2, rejected: 3 }

  belongs_to :community, inverse_of: :memberships
  belongs_to :user, inverse_of: :memberships

  validates :status, presence: true
  validates :admin, inclusion: { in: [true, false] }
  validates :community_id, uniqueness: { scope: [:user_id] }

  include ::UneekSsoClient::Model::Membership
  include ::UneekSsoClient::Model::Sync::Sidekiq

  after_update :touch_manifest, if: :admin_changed?
  after_destroy :touch_manifest

  def touch_manifest
    UneekPermission::Manifest.joins(:community).where(community: {id: community_id}).touch_all
  end

end

ActiveSupport.run_load_hooks(:membership, Membership)
