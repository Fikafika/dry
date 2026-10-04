# frozen_string_literal: true

require 'uneek_sso_client/model/tool'

class Tool < ApplicationRecord
  belongs_to :community, inverse_of: :tools

  has_many :user_tools, inverse_of: :tool, dependent: :destroy
  has_many :users, through: :user_tools, inverse_of: :tools

  validates :name, :application_name, :uri, :community, presence: true
  validates :name, uniqueness: { scope: :community_id }

  include ::UneekSsoClient::Model::Tool
end
