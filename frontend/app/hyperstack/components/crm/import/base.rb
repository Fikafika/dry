# backtick_javascript: true

class Crm
  class Import
    class Base < ::Crm::Base
      include Hyperstack::Router::Helpers
      include UrlHelper
      include WindowTitle

      def page_title
        Dynamic::Import::Setting.model_name.human
      end

      def schema_url
        return interpolate_path("/crm/:schema_id", {
          schema_id: request.params[:schema_id]
        })
      end

      def index_url
        return interpolate_path("/crm/:schema_id/import_settings", {
          schema_id: request.params[:schema_id]
        })
      end

      def new_url
        "#{index_url}/new"
      end

      def edit_url(id, query = nil)
        if query
          "#{index_url}/#{id}/edit?"+`$.param(#{query.to_n})`
        else
          "#{index_url}/#{id}/edit"
        end
      end

      def job_url(id, job_id)
        "#{index_url}/#{id}/jobs/#{job_id}"
      end

      def last_init_job_url(setting)
        j = setting.init_jobs.last
        j&.id ? job_url(setting.id, j.id) : index_url
      end

      def moment_format_value(v)
        m = `moment(#{v})`
        if `#{m}.isValid()`
          result = `#{m}.format(#{display_format})`
          if result == 'Invalid date'
            result = nil
          end
        end
        return result
      end

      def display_format
        I18n.t('format.date_time')
      end

      def back_button(variant: 'primary')
        Toolbar::Button(target: "/crm/#{request.params[:schema_id]}/import_settings", text: I18n.t('shared.back'), icon: 'chevron-left', is_flex: true, variant: variant)
      end

    end
  end
end
