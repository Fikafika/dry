# backtick_javascript: true

module Sso
  class Menu < HyperResource::Base

    def self.api_path
      "#{`UneekSso.url`}/menu"
    end

    def self.api_options
      @api_options ||= {
        params_keys: {
          where: nil,
        }
      }
    end

    has_many :applications, class_name: 'Sso::Application'
    has_many :hosts, class_name: 'Sso::Host'

  end

  class Host < HyperResource::Base

    has_many :communities, class_name: 'Sso::Community', inverse_of: :host

    translates :human_name
    globalize_accessors

  end

  class Community < HyperResource::Base

    belongs_to :host, class_name: 'Sso::Host', inverse_of: :communities
    has_one :application, class_name: 'Sso::Application'

    def logo_path
      "#{`UneekSso.url`}/communities/#{self.uuid}/logo.png?style=twenty" if self.has_logo
    end

  end

  class Application < HyperResource::Base

    translates :human_name
    globalize_accessors

  end
end



