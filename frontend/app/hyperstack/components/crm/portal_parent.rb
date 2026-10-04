class Crm
  class PortalParent < Crm::Base
    include DataOpenPanel

    render { content }

    def content
      DIV(class: 'crm-portal-parent') do
      end
    end
  end
end
