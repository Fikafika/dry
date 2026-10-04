# backtick_javascript: true

class Crm
  module Workflow
    module TriggerAction

      def execute_trigger_action(data)
        action_url  = data[:action]
        record_id   = data[:record_id]
        record_type = data[:record_type]
        return if action_url.blank?

        separator = action_url.include?('?') ? '&' : '?'
        url = "#{action_url}#{separator}record_id=#{record_id}&record_type=#{record_type}"

        target = data[:target]
        target.add_class('disabled') if target

        HyperResource::HTTP.get(url) do |response|
          if response.ok?
            alert(I18n.t("workflow.manual_trigger.success", object: data[:trigger_name] || data[:column_name]))
            reload
          else
            alert(I18n.t("workflow.manual_trigger.error", object: data[:trigger_name] || data[:column_name]))
          end
          target.remove_class('disabled') if target
        end
      end

    end
  end
end