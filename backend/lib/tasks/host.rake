# frozen_string_literal: true

namespace :host do
  desc 'clean data when migrate from prod to rec environment'
  task migrate: :environment do
    [
      Tool,
      UserTool,
      UserRole::DomainContext,
      Role,
      UserRole,
      Membership,
      User,
      Community,
    ].map(&:delete_all)

    ::UneekSsoClient.sync_all!
  end
end
