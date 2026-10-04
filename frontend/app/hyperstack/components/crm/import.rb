class Crm
  class Import < HyperComponent
    include Hyperstack::Router::Helpers
    include Router::Resources
    include UrlHelper

    render(DIV) { routes }

    def routes
      Resources("/crm/:schema_id/import_settings(/:import_setting_id)") do |match|
        ::Crm::Import::Settings(match: match)
      end
      Resources("/crm/:schema_id/import_settings/:import_setting_id/jobs(/:job_id)") do |match|
        ::Crm::Import::Jobs(match: match)
      end
    end

  end
end
