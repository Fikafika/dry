module Protocol; extend ActiveSupport::Concern

  module Helpers; extend ActiveSupport::Concern
    def formated_protocol(protocol)
      protocol == 'http' ? '' : "#{protocol}:"
    end

    # hypertext links open in a new tab
    def link_target_attributes(protocol)
      protocol == 'http' ? {target: '_blank', rel: 'noopener noreferrer'} : {}
    end
  end

  module DropdownItem
    extend ActiveSupport::Concern
    extend Helpers

    def dropdown_item_for_protocol(protocol, value, params = {}, show_icon = true)
      link_params = {class: 'dropdown-item'}.merge(params)
      link_params[:protocol] = protocol
      link_params[:value] = value

      Protocol::Link(link_params) do
        I(class: "fas fa-#{I18n.t("icons.protocols.#{protocol}")} fa-fw pr-4") {} if show_icon
        I18n.t("activerecord.values.dynamic/schema/attribute/base.protocols.#{protocol}")
      end
    end

    def record_data_for_link(current_klass, record_id)
      {
        "x-record-type" => current_klass,
        "x-record-id" => record_id,
      }
    end
  end

  module FormIcon; extend ActiveSupport::Concern
    def email_icon(value, params = {})
      link_params = {protocol: 'mailto', value: value}
      link_params.merge!(params)
      Protocol::Link(**params) do
        I(class: "fas fa-#{I18n.t("icons.protocols.mailto")} fa-fw edit-icon mx-3") {}
      end
    end
  end

  class Link < HyperComponent

    include Helpers

    param :value, default: ''
    param :protocol, default: 'http'
    collect_other_params_as :other_attributes

    # fired before react click event
    fires :jq_click

    after_mount do
      self.jq_node.on('click') do |event|
        # update component using existing method
        callback = Proc.new do |prop, value|
          method = :"update_#{prop}"
          send(method, value)
        end
        jq_click!(event, callback)
      end
    end

    before_unmount do
      self.jq_node.off('click')
    end

    render do
      A(href: "#{formated_protocol(protocol)}#{value}", **link_target_attributes(protocol), **other_attributes) do
        children.render
      end
    end

    def update_value(new_value)
      value = new_value
      self.jq_node.attr('href', "#{formated_protocol(protocol)}#{value}")
    end

  end

end