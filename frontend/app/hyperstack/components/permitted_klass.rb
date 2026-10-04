module PermittedKlass

  def permitted_klasses_for_action(klass_names, action, options = {})
    return [] unless klass_names&.any?
    unless User.current.admin?(schema_name)
      permissions = klass_permissions(klass_names, options)
      return [] unless permissions
      klass_names = klass_names.select do |k|
        klass_permitted?(k, permissions, action)
      end
    end
    return klass_names
  end

  def klass_permissions(klass_names, options = {})
    return @klass_permissions if @klass_permissions
    path = UneekPermission::Permission.collection_path(
      {
        where: {klass_name: klass_names},
        user_id: User.current.id
      }.merge(options)
    )
    ::HTTP.send(:get, path) do |response|
      if response.ok?
        @klass_permissions = response.json
        mutate
      end
    end

    return @klass_permissions
  end

  def klass_permitted?(klass_name, permissions, action)
    permissions.dig(klass_name, 'self')&.any? do |p|
      (p['grant'] & ::UneekPermission::Rule::ACTION_TO_FLAG[action]) != 0
    end
  end

end