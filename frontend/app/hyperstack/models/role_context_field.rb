class RoleContextField < ::HyperResource::Base

  belongs_to :role, class_name: 'Role'

  def self.api_path
    "#{api_prefix}/role_context_fields"
  end

end