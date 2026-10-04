require 'components/router/resources'

class Crm < HyperComponent
  include Hyperstack::Router::Helpers
  include ::Router::Resources
  include ::UrlHelper
  include ::SchemaLoading

  after_mount do
    ::Document.body.on('click.crm') do |event|
      link_element = event.target.closest('a')

      if link_element && link_element.is?('A') && link_element.attr('href')&.start_with?("mailto:") && schema&.const&.feature_enabled?('Dynamic::MailHosting::Feature')
        event.prevent_default

        Crm::MailEditor.recipients = link_element.attr('href').gsub("mailto:", "")
        Crm::MailEditor.open_from(link_element)
      elsif event.target.is?('A') && event.target.attr('href')&.start_with?("sms:") && schema.has_feature_enabled?('Dynamic::Sms::Feature')
        event.prevent_default
        App.history.push(App.location.add_params(sms_query(event)))
      end
    end
  end

  before_unmount do
    ::Document.body.off('click.crm')
  end

  render do
    observe User.current
    RouteWithRequest('/crm', exact: true) do
      with_authentication do
        Crm::SelectSchema()
      end
    end
    Crm::Settings()
    RouteWithRequest("/crm/:schema", exact: true, strict: true) do
      if User.current.try(:connected?)
        redirect_to_default_community_path
      else
        unless User.current.loading?
          with_authentication do
            DIV do
            end
          end
        end
      end
    end
    Resources(
      "/crm/:schema/table/:klass",
      {
        actions: {
          collection: ['search', 'last_search', 'edit', 'rules'],
          member: ['search', 'last_search', 'versions']
        }
      }
    ) do |match|
      if klass
        Crm::Index(klass: klass, match: match)
      elsif schema
        schema.after_constants_loaded { mutate }
        schema_loading_message
      end
    end
    redirect_old_urls
    Crm::Forms()
    Crm::Import()
    Crm::DocGen()
    Crm::Merge()
    Crm::Copy()
    Crm::Redirection()
  end

  def menu
    observe User.current.menus.merge_where(schema_name: request.params[:schema], name: 'crm').first
  end

  def klasses
    schema.const_klasses
  end

  def klass
    return klasses.detect { |k| k.model_name.route_key == request.params[:klass] }
  end

  def redirect_to_default_community_path
    return unless schema&.loaded?

    unless menu&.loaded?
      menu&.__promise__&.then { mutate }
      return
    end

    if first_menu_item_link
      Redirect(first_menu_item_link)
    elsif User.current.admin?(request.params[:schema])
      Redirect("/crm/#{request.params[:schema]}/settings")
    end
  end

  def first_menu_item_link
    menu.roots.first&.link
  end

  def schema_loading_message
    DIV(class: 'm-2 fa fa-spinner fa-pulse'){}
  end

  def sms_query(event)
    sms_klass = schema.features.detect {|f| f.name == 'Dynamic::Sms::Feature' }&.concerns.detect {|c| c.name == 'Sms'}&.klass
    return {
      rp: url_for(klass: sms_klass&.const, action: 'new') + '?' + encode_url_params(
        target_record_id: event.target.attr("x-record-id"),
        target_record_type: event.target.attr("x-record-type"),
        phone_number: event.target.attr('href').gsub("sms:", ""),
      ),
    }
  end

  def redirect_old_urls
    Resources(
      "/crm/:schema/:mode(list|map|dashboard|chart|kanban)/:klass",
      {
        actions: {
          collection: ['search', 'last_search', 'edit'],
          member: ['search', 'last_search']
        }
      }
    ) do |match|
      new_url = request.location.pathname.gsub(/\/crm\/([^\/]*)\/[^\/]*/, '/crm/\1/table') + request.location.search
      App.history.replace(new_url)
    end
  end

  module Routes
    module Helpers; extend ActiveSupport::Concern
      include ::UrlHelper

      def index_url(klass)
        return unless request
        return interpolate_path("/crm/:schema/:mode/:klass", {
          schema: request.params[:schema] || request.params[:schema_id],
          klass: klass.model_name.route_key,
          mode: request.params[:mode] || 'table',
        })
      end

      def new_url(klass)
        "#{index_url(klass)}/new"
      end

      def show_url(klass, id)
        "#{index_url(klass)}/#{id}"
      end

      def edit_url(klass, id)
        "#{index_url(klass)}/#{id}/edit"
      end

      def destroy_url(klass, id)
        "#{index_url(klass)}/#{id}/destroy"
      end

      def search_url(klass, query)
        return index_url(klass) unless query.any?
        return "#{index_url(klass)}/search?#{encode_url_params(query)}"
      end

    end
  end

  class Base < ::HyperComponent
    include Hyperstack::Router::Helpers
    include ::Router::Resources
    include Routes::Helpers
    include ::SchemaLoading

    def panel_param(s = self.side)
      "#{s[0]}p"
    end

    def side
      other_params[:side] || 'right'
    end

    def highlight(line)
      # implemented in subclasses
    end
  end

end

