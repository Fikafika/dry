# frozen_string_literal: true

require 'uneek_sso_client/model/user'
require 'uneek_sso_client/model/sync/sidekiq'
require 'dynamic/elasticsearch/callbacks'

class User < ApplicationRecord

  has_many :memberships, inverse_of: :user, dependent: :destroy
  has_many :communities, through: :memberships, inverse_of: :users

  has_many :user_tools, inverse_of: :user, dependent: :destroy
  has_many :tools, through: :user_tools, inverse_of: :users

  has_many :user_roles, inverse_of: :user, dependent: :destroy
  has_many :roles, through: :user_roles, inverse_of: :users

  validates :super_admin, inclusion: { in: [true, false] }

  devise :cas_authenticatable,
         :jwt_header_authenticatable,
         :currentable,
         :validatable


  include ::UneekSsoClient::Model::User
  include ::UneekSsoClient::Model::Sync::Sidekiq
  include ::UneekPermission::User
  include ::OpenSearch::Model
  include ::Dynamic::Elasticsearch::Callbacks
  include ::Dynamic::Permission::OpenSearch::User

  def self.attributes_blacklist
    [
      :uneek_sso_syncable_fingerprint,
      :uneek_sso_client_syncable_fingerprint,
    ]
  end

  concerning  :Identification do
    class_methods do
      def name_attribute
        'full_name'
      end
    end

    def name
      [first_name, last_name].compact.join(' ')
    end
    alias :full_name :name

    def name_or_login
      if first_name.present? || last_name.present?
        name
      else
        login
      end
    end
  end

  def admin?(schema_id = nil)
    return true if super_admin?
    return false unless schema_id
    return memberships.any? do |m|
      m.admin && m.status == 'active' && m.community &&
      (m.community.schema_id == schema_id || m.community.schema.name == schema_id)
    end
  end

  alias_method :is_admin?, :admin?

  def as_indexed_json(options = {})
    {
      'id' => self.id,
      'first_name' => self.first_name,
      'last_name' => self.last_name,
      'language' => self.language,
      'email' => self.email,
      self.class.name_attribute => self.try(self.class.name_attribute),
    }
  end

  def attributes_for_opensearch_user
    ['first_name', 'last_name', 'language', 'email']
  end

  def trigger_update_es_document?
    (self.changes.keys & attributes_for_opensearch_user).any?
  end

  concerning :Permission do

    RESERVED_KLASS_NAMES_FOR_PERMISSIONS = [
      'DocGen::Template',
      'Export::Setting',
      'Merge::Setting',
    ].freeze

    KLASS_HAVING_SCHEMA_FOR_PERMISSIONS = [
      'Dynamic::Import::Setting',
      'Dynamic::Schema::Feature',
    ].freeze

    def permissions_for_features
      result = {}
      return result if self.super_admin?
      absolute_reserved_klasses_by_schema_id = {}

      self.memberships.each do |m|
        next if m.admin?
        s = m.community.schema
        next unless s
        s.load # Needed in order to constantize reserved klass and resolve permissions on inherited classes
        absolute_reserved_klasses_by_schema_id[s.id] = s.reserved.name + '::'
      end

      absolute_reserved_klasses_by_schema_id.each do |id, arp|
        absolute_reserved_klasses_by_schema_id[id] = RESERVED_KLASS_NAMES_FOR_PERMISSIONS.map {|r| arp + r}
      end

      reserved_klass_names = absolute_reserved_klasses_by_schema_id.values.flatten
      permissions = UneekPermission::Retriever::Permission.new(
        user: self,
        klass_name: KLASS_HAVING_SCHEMA_FOR_PERMISSIONS + reserved_klass_names
      ).retrieve(as: :hash)

      KLASS_HAVING_SCHEMA_FOR_PERMISSIONS.each do |c_name|
        permissions.dig(c_name, :self).each do |perm|
          result[perm['schema_id']] ||= {}
          result[perm['schema_id']][c_name] ||= {}
          k = perm['instance_id'] || 'self'
          result[perm['schema_id']][c_name][k] = perm['permission']
        end
      end

      absolute_reserved_klasses_by_schema_id.each do |id, klass_names|
        klass_names.each do |k_name|
          permissions.dig(k_name, :self)&.each do |perm|
            result[id] ||= {}
            result[id][k_name] ||= {}
            k = perm['instance_id'] || 'self'
            result[id][k_name][k] = perm['permission']
          end
        end
      end

      return result
    end

  end

end
