# frozen_string_literal: true

require 'uneek_sso_client/model/role_context_field'

class RoleContextField < ApplicationRecord
  translates :human_name, fallbacks_for_empty_translations: true
  globalize_accessors

  belongs_to :role, inverse_of: :role_context_fields

  validates :name, presence: true, uniqueness: { scope: :role_id }

  include ::UneekSsoClient::Model::RoleContextField
end
