class Role < ::HyperResource::Base

  has_many :users, class_name: 'User', inverse_of: :roles
  has_many :role_context_fields, class_name: 'RoleContextField', inverse_of: :roles
  belongs_to :community, class_name: 'Community'

  def self.api_path
    "#{api_prefix}/roles"
  end

  def self.icon
    'users'
  end

end