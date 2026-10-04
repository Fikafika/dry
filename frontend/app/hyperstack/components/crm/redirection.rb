# backtick_javascript: true

class Crm

  class Redirection < HyperComponent
    include Hyperstack::Router::Helpers
    include ::Router::Resources

    render do
      Resources("/crm/:schema_id/redirections", authentication: 'optional') do |match|
        next unless match.params[:schema_id] && match.params[:id]
        Loading(schema_id: match.params[:schema_id], id: match.params[:id])
      end
    end

    class Loading < HyperComponent
      include Hyperstack::Router::Helpers
      include ::Router::Resources::Request::Helpers

      param :schema_id
      param :id

      render do
        layout do
          if record.not_found? || record.status_code == 401
            invalid_redirection
          elsif record.loaded?
            if need_loaded_schema? && !schema_loaded?
              loading
            else
              url = compute_url
              if url
                redirect(url)
              else
                invalid_redirection
              end
            end
          else
            loading
          end
        end
      end

      def layout
        DIV(class: 'p-2') do
          yield
        end
      end

      def record
        observe @record ||= Dynamic::Redirection.where(schema_id: schema_id).includes(
          schema: 1,
          evaluate: {args: [request.params.to_h], as: :evaluation_result},
        ).find(id)
      end

      def invalid_redirection
        DIV(class: 'alert alert-danger') do
          I18n.t('crm.redirection.invalid')
        end
      end

      def need_loaded_schema?
        !!url_helper.try(:need_loaded_schema?)
      end

      def schema_loaded?
        schema.loaded? && schema.constants_loaded?
      end

      def url_helper
        return unless record.evaluation_result.is_a?(::Hash)
        type = record.evaluation_result['type']
        return unless type.present?
        return self.class.const_get(type)
      end

      def schema
        @schema ||= Dynamic::Schema.load(schema_id) do
          mutate
        end
      end

      def loading
        DIV {}
      end

      def redirect(url)
        return '' unless url.present?
        if url.start_with?('/crm') # frontend ?
          Redirect(url)
        else
          `window.location = #{url}`
          '' # display nothing
        end
      end

      def compute_url
        helper = self.url_helper
        return unless helper
        return helper.url_for(record.evaluation_result['params'] || {})
      end

      module Form
        extend ::UrlHelper

        def self.url_for(params)
          return unless params['schema_id'] && params['form_id']

          result = "/crm/#{params['schema_id']}/forms/#{params['form_id']}"
          [
            'source_record_id',
            'source_record_type',
            'target_record_id',
            'target_record_type',
            'options',
            'params',
          ].each do |param_name|
            next unless params.has_key?(param_name)
            result = add_param_to_url(result, param_name, params[param_name])
          end

          if params['record_as'] == 'target'
            result = add_param_to_url(result, 'target_record_id', params['id'])
            result = add_param_to_url(result, 'target_record_type', params['klass_name'])
          else
            result = add_param_to_url(result, 'source_record_id', params['id'])
            result = add_param_to_url(result, 'source_record_type', params['klass_name'])
          end

          return result
        end
      end

      module Vcard

        def self.url_for(params)
          return unless params['schema_name'].present? && params['route_key'].present? && params['id'].present?
          path = "#{ENV['APP_PATH_PREFIX']}/api/d/#{params[:schema_name].underscore}/#{params[:route_key]}/#{params[:id]}.vcf"
          return `window.location.origin` + path
        end
      end

    end

  end

end
