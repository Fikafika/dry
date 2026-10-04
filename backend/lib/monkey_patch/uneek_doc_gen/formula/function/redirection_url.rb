# frozen_string_literal: true

load 'app/controllers/concerns/find_by_id_or_name.rb'

module UneekDocGen
  class Formula
    module Function
      class RedirectionUrl < ::Uneek::Formula::Function::Base
        include FindByIdOrName

        def eval(options = {}.with_indifferent_access)
          args = values_from_args(function_arg, options)
          redirection_id = args[0]
          return '' unless redirection_id.present?

          schema = self.schema_form_options(options)
          return unless schema

          redirection = find_by_id_or_name(schema.redirections, redirection_id)
          return '' unless redirection

          result = "#{ENV['DYNAMO_PROTOCOL']}://#{ENV['DYNAMO_HOST']}/crm/#{schema.name.underscore}/redirections/#{redirection.name.underscore}"

          record = record_from_options(options)

          if record
            params = {}
            params['for'] = record.id
            if params.any?
              result = "#{result}?#{params.to_query}"
            end
          end

          return result
        end

        private

        def schema_form_options(options)
          record = record_from_options(options)
          return unless record
          schema_name = record.class.module_parent.name.demodulize
          return Dynamic::Schema.loaded_schemas[schema_name] || Dynamic::Schema.where(name: schema_name).first
        end

        def record_from_options(options)
          options[:formula]&.instance_variable_get(:@eval_options).try(:[], :record)
        end

      end
    end
  end
end
