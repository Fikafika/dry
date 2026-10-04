# frozen_string_literal: true

require 'uneek_sso_client/model/user_tool'

class UserTool < ApplicationRecord
  belongs_to :user, inverse_of: :user_tools
  belongs_to :tool, inverse_of: :user_tools

  validates :tool_id, uniqueness: { scope: [:user_id] }

  include ::UneekSsoClient::Model::UserTool
end
