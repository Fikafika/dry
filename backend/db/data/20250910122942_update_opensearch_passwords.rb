# frozen_string_literal: true

class UpdateOpensearchPasswords < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    Role.where(admin: false).find_each do |r|
      r.put_os_role
    end
    User.find_in_batches(batch_size: 50) do |users|
      body = []
      users.each do |u|
        response = OpenSearch::Model.client.security.get_user(username: u.os_username, ignore: [404])
        if response.status == 404
          u.put_os_user
        else
          body << {
            op: 'replace',
            path: '/' + u.os_username,
            value: {
              password: u.os_password,
              opendistro_security_roles: u.os_roles,
              attributes: u.os_user_role_context
            }
          }
        end
      end
      OpenSearch::Model.client.security.patch_user(username: '', body: body)
    end
    UneekPermission::PredefinedReceiver::Public.instance.put_os_role_and_user
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
