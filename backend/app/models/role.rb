# frozen_string_literal: true

require 'uneek_sso_client/model/role'

class Role < ApplicationRecord
  translates :human_name, fallbacks_for_empty_translations: true
  globalize_accessors

  belongs_to :community, inverse_of: :roles

  has_many :user_roles, inverse_of: :role, dependent: :destroy
  has_many :users, through: :user_roles, inverse_of: :roles
  has_many :role_context_fields, inverse_of: :role, dependent: :destroy

  validates :default, inclusion: { in: [true, false] }
  validates :name, presence: true, uniqueness: { scope: [:community_id] }

  after_commit :create_admin_rules, on: :create
  after_commit :create_menu_permissions, on: :create, unless: :admin?

  after_update :touch_manifest, if: :loose_admin_privilege?

  include ::UneekSsoClient::Model::Role
  include ::OpenSearch::Model
  include ::Dynamic::Permission::OpenSearch::Role

  PERMITTED_KLASSES_FOR_ADMIN = [
    'Dynamic::Form',
    'Dynamic::Import::Setting',
  ].freeze

  PERMITTED_RESERVED_KLASSES_FOR_ADMIN = [
    'DocGen::Template',
    'Export::Setting',
    'Menu',
    'Menu::Item',
    'Merge::Setting',
  ].freeze

  private

  def create_admin_rules
    return unless self.admin
    s = self.community.schema
    s.load
    UneekPermission::Rule.create_with(
      schema: s,
    ).find_or_create_by!(
      receiver: self,
      klass_name: s.const_dynamic_record.name,
      grant: 15
    )
    create_admin_rules_for_reserved_klasses
    create_admin_rules_for_schema_dependant_klasses
  end

  def create_admin_rules_for_reserved_klasses
    return unless self.admin
    s = self.community.schema
    const_reserved_name = "#{s.const.name}::#{s.class::RESERVED_CONSTANT}::"
    PERMITTED_RESERVED_KLASSES_FOR_ADMIN.each do |k|
      UneekPermission::Rule.create_with(
        schema: s,
      ).find_or_create_by!(
        receiver: self,
        klass_name: const_reserved_name + k,
        grant: 15,
      )
    end
  end

  def create_admin_rules_for_schema_dependant_klasses
    return unless self.admin
    s = self.community.schema
    PERMITTED_KLASSES_FOR_ADMIN.each do |k|
      UneekPermission::Rule.create_with(
        schema: s,
        instance_field: 'schema_id',
        expression_method: '==',
        expression_value: s.id,
      ).find_or_create_by!(
        receiver: self,
        klass_name: k,
        grant: 15,
      )
    end
  end

  def create_menu_permissions
    return if self.admin
    s = self.community.schema
    s.load unless s.loaded?
    const_reserved_name = "#{s.const.name}::#{s.class::RESERVED_CONSTANT}::"
    UneekPermission::Rule.create_with(
      schema: s,
      instance_field: 'user_id',
      user_field: 'id',
    ).find_or_create_by!(
      receiver: self,
      klass_name: const_reserved_name + 'Menu',
      grant: 15,
    )
    UneekPermission::Rule.create_with(
      schema: s,
      instance_field: 'menu.user_id',
      user_field: 'id',
    ).find_or_create_by!(
      receiver: self,
      klass_name: const_reserved_name + 'Menu::Item',
      grant: 15,
    )
  end

  def touch_manifest
    UneekPermission::Manifest.joins(:community).where(community: {id: community_id}).touch_all
  end

  def loose_admin_privilege?
    self.admin_changed?(from: true, to: false) || self.admin_changed?(from: true, to: nil)
  end
end
