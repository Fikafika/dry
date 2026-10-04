module Dynamic
  class Position
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Position',
          human_name_en: 'Position',
          mandatory: true,
          visible: false,
        }
      end

      def self.load(schema)
        Dynamic::Position.mount(schema)
      end

      module DynamicRecord; extend ActiveSupport::Concern
        included do
          scope :join_positions, -> (attribute_name) do
            logical_attr = attribute_name
            sql_attr = logical_attr

            if klass.dynamic_mapping.has_key?(logical_attr)
              sql_attr = klass.dynamic_mapping[logical_attr]
            end

            self_table = klass.table_name
            position_table = klass.module_parent::R::Position.table_name

            if klass.column_names.include?(sql_attr)
              joins(
                "LEFT JOIN #{position_table} AS positions ON positions.owner_id = #{self_table}.id
                  AND positions.context_value IS NOT DISTINCT FROM #{self_table}.#{sql_attr}
                  AND positions.context_attr = #{connection.quote(logical_attr)}"
              )
            else

              association_table = klass.module_parent::DynamicAssociation.table_name
              schema_association_id = reflect_on_association(sql_attr.sub(/_id$/, '')).schema_association_id
              joins("
                LEFT JOIN #{association_table} AS position_association ON position_association.association_owner_id = #{self_table}.id
                  AND position_association.association_owner_type = #{connection.quote(klass.name)}
                  AND position_association.schema_association_id = #{connection.quote(schema_association_id)}
                  AND position_association.schema_association_type = 'Dynamic::Schema::Association::Base'
                  AND position_association.deleted_at IS NULL

                LEFT JOIN #{position_table} AS positions
                  ON positions.owner_id = #{self_table}.id
                  AND positions.context_value IS NOT DISTINCT FROM position_association.association_target_id
                  AND positions.context_attr = #{connection.quote(logical_attr)}
              ")
            end
          end
        end
      end
    end
  end
end
