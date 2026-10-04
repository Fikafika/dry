# backtick_javascript: true

class Crm
  module Workflow
    module TriggerCache

      def self.triggers_cache
        @triggers_cache ||= {}
      end

      def self.triggers_for(record_type, record_id)
        cache = triggers_cache[record_type]
        return nil unless cache
        cache[record_id]
      end

      def self.clear_cache_for(*record_types)
        record_types.each { |rt| triggers_cache.delete(rt) }
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def triggers_for(record_type, record_id)
          Crm::Workflow::TriggerCache.triggers_for(record_type, record_id)
        end
      end

      private

      def resolve_trigger_klass
        @trigger_klass ||= "#{klass.parent.name}::R::Workflow::ManualTrigger".safe_constantize
      end

      def init_trigger_cache
        return unless klass&.parent&.feature_enabled?('Dynamic::Datatable::Style::Feature')
        return unless has_button_columns?
        return unless resolve_trigger_klass
        return if @trigger_cache_initialized
        @trigger_cache_initialized = true
        load_triggers
      end

      def reset_trigger_cache
        @trigger_cache_initialized = false
        Crm::Workflow::TriggerCache.clear_cache_for(*button_column_record_types) if @trigger_klass
      end

      def reload_trigger_cache
        reset_trigger_cache
        init_trigger_cache
      end

      def has_button_columns?
        visible_columns.any? { |col| col.button_style }
      end

      def button_column_record_types
        visible_columns.each_with_object([]) do |col, types|
          next unless col.button_style
          type = col.record_type
          types << type unless types.include?(type)
        end
      end

      def load_triggers
        return unless @trigger_klass
        @trigger_record_types = button_column_record_types
        @trigger_klass.update_cache([:all])
        triggers_relation = @trigger_klass.where(record_type: @trigger_record_types).limit(20000).all
        triggers_relation.__promise__.then do
          populate_trigger_cache(triggers_relation)
          draw
        end
      end

      def populate_trigger_cache(triggers_relation)
        cache = Crm::Workflow::TriggerCache.triggers_cache
        @trigger_record_types.each { |rt| cache[rt] = {} }
        return unless triggers_relation
        triggers_relation.each do |t|
          record_type = t.record_type
          rid = t.record_id
          next if rid.blank?
          cache[record_type] ||= {}
          cache[record_type][rid] ||= []
          entry = {
            id: t.id,
            name: t.name,
            action: t.action,
            icon: t.icon,
            enabled: t.enabled != false
          }
          idx = cache[record_type][rid].index { |x| x[:id] == t.id }
          if idx
            cache[record_type][rid][idx] = entry
          else
            cache[record_type][rid] << entry
          end
        end
      end

    end
  end
end