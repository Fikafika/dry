# backtick_javascript: true

require 'active_support'
require 'active_support/concern'
require 'components/hyper_component'
require 'components/error_boundary'

class App < HyperComponent
  include Hyperstack::Router
  include Hyperstack::Router::Helpers

  before_mount do
    [
      :alert,
      :button,
      :carousel,
      :collapse,
      :dropdown,
      :modal,
      :popover,
      :scrollspy,
      :tab,
      :toast,
      :tooltip,
      :responsive_tabs,
    ].each do |m|
      next if ::Element.instance_methods.include?(m)
      ::Element.alias_native m, m.to_s.camelize(:lower)
    end

    init_env_from_meta_tags

    if Hyperstack.env != 'test'
      @saved_path = `UneekSso.UserSessions.deleteSavedPath()`
    end
  end

  after_mount do
    ::Document.on("userConnected.uneekSso") do
      ::User.current(true) # should already be set by cable but we never know...
    end
  end

  render(DIV, class: "router-top-level") do
    if Hyperstack.env == 'test'
      Test()
    else
      with_restore_saved_path do
        with_force_reload_managment do
          ErrorBoundary() do
            Settings()
            Crm()
            Crm::PortalParent()
            PublicPage()
          end
        end
      end
    end
  end

  @@force_reload = nil

  def with_force_reload_managment
    @@force_reload = false if @@force_reload.nil?
    observe @@force_reload
    @@current = self
    unless @@force_reload
      yield
    end
  end

  def init_env_from_meta_tags
    ::Element['meta'].each do |e|
      meta_name = e.attr('name')
      next if meta_name == 'viewport'
      ENV[meta_name.gsub('-', '_').upcase] = e.attr('content')
    end
  end

  def with_restore_saved_path
    if @saved_path && comes_from_cas? && @saved_path != `window.location.pathname`
      path = @saved_path
      @saved_path = nil
      App.history.replace(path)
      mutate
    else
      yield
    end
  end

  def comes_from_cas?
    `document.referrer` && `document.referrer` =~ /sso|cas/ # need a list of allowed cas domains ?
  end

  def self.current_community
    s = request.params[:schema] || request.params[:schema_id]
    return unless s
    ::User.current.communities.detect do |c|
      c.permalink == s || c.schema_name.to_s.underscore == s
    end
  end

  module Appearance; extend ActiveSupport::Concern

    class_methods do

      def change_theme_if_missing
        e = ::Element.find('#application-theme')
        return unless e.length > 0
        s = request.params[:schema] || request.params[:schema_id]
        return unless s && !e.attr('href').include?(s)
        c = self.current_community
        return unless c&.theme
        c.theme.schema = Dynamic::Schema.new(name: c.schema_name.underscore)
        change_theme(c.theme.path, true)
      end

      def change_theme(path, check = false)
        e = ::Element.find('#application-theme')
        return if e.length == 0
        path = path || e.data('application-css')
        return if e.attr('href') == path

        p = Proc.new do
          e = ::Element.find('#application-theme')
          next if e.attr('href') == path
          puts "change theme #{path}"
          body = ::Element.find('body')
          body.css('opacity', 0)
          e.attr('href', path)
          after(1) do
            body.css('opacity', 1)
          end
        end

        if check
          @last_path = path
          waiting_for(path) do
            if path == @last_path
              p.call
            end
          end
        else
          p.call
        end
      end

      def waiting_for(path, max_attempts = 5, attempts = 0, &block)

        if attempts > max_attempts
          return
        end

        time = attempts * 2

        after(time) do
          ::HyperResource::HTTP.head(path) do |resp|
            if resp.ok?
              yield
            else
              waiting_for(path, max_attempts, attempts + 1, &block)
            end
          end
        end
      end

    end

  end; include Appearance

  def self.reload
    Dynamic::Schema.unload_all
    [
      Dynamic::Schema,
      User,
      Dynamic::Form,
      Dynamic::Menu,
      Dynamic::Notification,
      Dynamic::Import::Setting,
      Dynamic::Import::Job::Base,
      Dynamic::Cascade,
      Dynamic::Layout,
      Sso::Menu,
    ].map(&:clear_cache)

    User.current = nil
    @@force_reload = true
    @@current.mutate

    after(0.2) do
      @@force_reload = false
      @@current.mutate
    end
    true
  end

end
