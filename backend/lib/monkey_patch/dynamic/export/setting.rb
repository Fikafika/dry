ActiveSupport.on_load(:dynamic_export_setting) do

  concerning :Permissions do
    included do
      include UneekPermission::ControlledKlass

      def associations_for_uneek_permissions
        nil
      end
    end
  end

  def record_to_exports
    scope = records_klass.includes(includes_attributes)
    scope = relation_scope.call(scope, scope) if relation_scope
    return scope
  end

  def relation_scope
    return unless scopes_params&.any? || scope_for_records_to_export["where"] || scope_for_records_to_export["where_not"]
    Proc.new do |relation, klass|
      relation = relation.where(scope_for_records_to_export["where"]) if scope_for_records_to_export["where"]
      relation = relation.where.not(scope_for_records_to_export["where_not"]) if scope_for_records_to_export["where_not"]
      scopes_params&.each do |s|
        raise "forbidden scope #{s["name"]}" unless allowed_scopes.include?(s["name"])
        filter_args = Dynamic::Filters::Converter.new(s["args"]).filters
        relation = relation.send(s["name"], filter_args)
      end
      relation
    end
  end

  def scopes_params
    @scopes_params ||= case scope_for_records_to_export["scopes"]
      when Hash
        scope_for_records_to_export["scopes"]&.with_num_keys_to_array&.map do |h|
          h["args"] = h["args"].with_num_keys_to_array if h["args"].is_a?(Hash)
          h
        end || []
      when Array
        scope_for_records_to_export["scopes"]
      end
  end

  def allowed_scopes
    ['where_filters', 'where_query']
  end
end