module UneekPermission
  class Rule < ::HyperResource::Base

    include ::Icon

    ACTION_TO_FLAG = {
      C: 1 << 3,
      R: 1 << 2,
      U: 1 << 1,
      D: 1 << 0
    }.freeze

    DOMAIN_OPERATION_METHODS_BY_TYPE = {
      'Integer' => ['==', '!', '>', '<', '<=', '>='],
      'Float' => ['==', '!=', '>', '<', '<=', '>='],
      'String' => ['==', '!=', 'start_with?', 'end_with?', 'include?', 'exclude?'],
      'Boolean' => ['=='],
      'Enum' => ['==', '!='],
      'Uuid' => ['==', '!='],
      'DateTime' => ['==', '!=', '>', '<', '<=', '>='],
    }.freeze

    belongs_to :receiver, polymorphic: true

    def self.permissions
      return ACTION_TO_FLAG.keys
    end

    def self.api_path
      "#{api_prefix}/uneek_permission/rules"
    end

    def self.feature
      'Dynamic::Permission::Feature'
    end

    def actions
      result = {}
      self.class.permissions.each do |action|
        result[action] = (respond_to(:permission) && permission.include?(action.to_s))
      end
      result
    end

  end

  class Permission < ::HyperResource::Base

    def self.api_path
      "#{api_prefix}/uneek_permission/permissions"
    end

  end

  class User < ::HyperResource::Base

    def self.api_path
      "#{api_prefix}/uneek_permission/users_for_instances"
    end

  end

  module PredefinedReceiver

    class Public < ::HyperResource::Base
      include ::Icon
    end

  end

end
