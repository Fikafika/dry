class Crm
  class Merge < HyperComponent
    include Hyperstack::Router::Helpers
    include Router::Resources
    include UrlHelper

    render(DIV) { routes }

    def routes
      Resources("/crm/:schema_id/merge_settings(/:setting_id)") do |match|
        Crm::Merge::Setting(match: match)
      end
    end

  end
end
