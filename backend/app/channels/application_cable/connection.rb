# frozen_string_literal: true

require 'resolv'

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    identified_by :session_id, :ip

    def connect
      self.session_id = session&.id
      self.ip = request.ip if authorized_ws_api_user? || local_network_connection?
      reject_unauthorized_connection unless authorized?
      logger.add_tags 'ActionCable', self.session_id, self.ip
    end

    def session
      env['rack.session']
    end

  private

    def authorized?
      return authorized_session? || authorized_ws_api_user? || local_network_connection?
    end

    def authorized_session?
      session_id # enough ?
    end

    def authorized_ws_api_user?
      return ENV.has_key?('DYNAMO_WS_PASSWORD') && authenticate_with_http_basic do |username, password|
        ENV['DYNAMO_WS_USERNAME'] == username && ENV['DYNAMO_WS_PASSWORD'] == password
      end
    end

    def local_network_connection?
      request.env['HTTP_ORIGIN'].nil? && request.ip =~ authorized_networks_regex
    end

    def authorized_networks_regex
      return @authorized_networks_regex if @authorized_networks_regex

      domain_ips = ENV['AUTHORIZED_DOMAINS'].to_s.split(' ').map do |d|
        Resolv.getaddresses(d)
      end.flatten

      return Regexp.new('\z\A') unless domain_ips.any?

      @authorized_networks_regex = Regexp.new(
        domain_ips.map do |e|
          '\A' + Regexp.escape(e.gsub(/\d+\z/, ''))
        end.uniq.join('|')
      )

      return @authorized_networks_regex
    end

  end
end
