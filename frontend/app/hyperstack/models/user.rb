# backtick_javascript: true

if RUBY_ENGINE == 'opal'

  class User < ::HyperResource::Base

    class << self

      def api_path
        "#{api_prefix}/users"
      end

      def current(reload = false)
        return @current if @current && !reload

        result = @current || self.new

        ::HTTP.send(:get, "#{api_prefix}/user.json") do |response|
          result.status_code = response.status_code
          if response.ok?
            json = response.json rescue nil
          end

          result.refresh(json, json.is_a?(Hash) ? nil : (response.json rescue {:message => 'error'}))

          yield(result) if block_given?
        end

        @current = result

        return result
      end

      def current=(v)
        @current = v
      end

      def owns_sign_in_enabled?
        `window.sessionStorage.getItem("sign_in_enabled") === "false"`
      end

      def sign_in_enabled?
        `window.localStorage.getItem("sign_in_enabled") !== "false"`
      end

      def sign_in_enabled=(sign_in_enabled)
        if !sign_in_enabled
          %x{
            window.localStorage.setItem("sign_in_enabled", "false")
            window.sessionStorage.setItem("sign_in_enabled", "false")
          }
        elsif owns_sign_in_enabled?
          %x{
            window.sessionStorage.removeItem("sign_in_enabled")
            window.localStorage.removeItem("sign_in_enabled")
          }
        end
      end

    end

    has_many :communities, class_name: 'Community', foreign_key: nil # no foreign_key in order to prevent to have a community with a scope where[user_id] = ...
    has_many :memberships, class_name: 'Membership', inverse_of: :user
    has_many :roles, class_name: 'Role', inverse_of: :users

    def refresh(json, errors = nil)
      if errors
        self.attributes = {}
        self.errors = errors
      else
        self.json = json
        self.errors = {}
      end
      # TODO status_code

      json_ = json || {}
      if @previous_json != json_
        @previous_json = json_

        set_locale unless errors&.any?

        clear_schemas if json.blank?

        mutate
      end
    end

    def set_locale
      if self.language.present?
        I18n.locale = self.language
      else
        I18n.locale = I18n.default_locale
      end
    end

    def clear_schemas
      Dynamic::Schema.update_cache([:find, :all])
    end

    def admin?(schema_name)
      return false unless connected?
      return true if super_admin
      return false unless schema_name
      if schema_name.is_a?(String)
        schema = Dynamic::Schema.load(schema_name)
      else
        schema = schema_name
      end
      return false unless schema.loaded?
      return memberships.any?{|m| m.admin && m.status == 'active' && m.community && m.community.schema_id == schema.id }
    end

    def connected?
      !new_record?
    end

    def sign_in
      if xhr_sign_in?
        show_sign_in_modal(true)
      else
        `UneekSso.UserSessions._redirectToCasLogin()`
      end
    end

    def xhr_sign_in?
      true
    end

    def sign_out
      self.class.sign_in_enabled = false
      HTTP.get("#{self.class.api_path}/sign_out", crossDomain: false, xhrFields: { withCredentials: true }).fail do |response|
        if `(#{response.xhr}.readyState === 0) && (#{response.xhr}.status === 0)` # CORS error
          `window.location = #{"#{self.class.api_path}/sign_out".to_n}`
        end
      end.then do |response|
        self.class.sign_in_enabled = true
        ::User.current(true)
      end
    end

    def show_sign_in_modal(show = true)
      return if show && !self.class.sign_in_enabled?
      modal = ::Element.find('#sign-in-modal')
      modal.modal(show ? 'show' : 'hide')
    end

    def jwts
      @jwts ||= {}
    end

    def name
      [first_name, last_name].compact.join(' ')
    end

    def name_or_login
      if first_name.present? || last_name.present?
        name
      else
        login
      end
    end

    def self.icon
      'user'
    end

    has_many(:menus, class_name: '::Dynamic::Menu', foreign_key: :user_id, relation_class_name: '::Dynamic::Menu::Relation')
    has_many(:queries, class_name: '::Dynamic::Query::Base', foreign_key: :user_id, relation_class_name: '::Dynamic::Query::Relation')

  end

  def can_create?(klass_name, options = {})
    can_perform_action?('C', klass_name, options)
  end

  def can_read?(klass_name, options = {})
    can_perform_action?('R', klass_name, options)
  end

  def can_update?(lass_name, options = {})
    can_perform_action?('U', klass_name, options)
  end

  def can_delete?(klass_name, options = {})
    can_perform_action?('D', klass_name, options)
  end

  def can_perform_action?(action, klass_name, options = {})
    schema = options[:schema]
    id = options[:id]

    if schema.nil? && klass_name.start_with?('D')
      schema_name = klass_name.split('::')[1]
      schema = Dynamic::Schema.load(schema_name)
    end

    return true if admin?(schema)
    return false unless schema
    klass_permissions = permissions_for_features&.dig(schema.id, klass_name)
    return false unless klass_permissions
    return !!klass_permissions[id]&.include?(action) || !!klass_permissions['self']&.include?(action)
  end

else

  class User < ::ApplicationRecord
    devise
  end

end
