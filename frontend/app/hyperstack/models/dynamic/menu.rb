require_relative 'reserved_relation'

module Dynamic
  class Menu < ::Dynamic::Base
    define_api_path # /api/d/uneek/r__menus

    class << self

      def includes_for_load
        {
          items: {
            include: {
              translations: 1,
              permitted: 1,
            }
          }
        }
      end

    end

    def roots
      return [] if self.class == Dynamic::Menu # abstract
      self.items&.select{|item| !item.parent_id}&.sort_by{ |item| item.position || 0} || []
    end

    def item_by_id(id)
      return nil unless id.present?
      return self.items.detect{|i| i.id == id}
    end

    def save_items_position
      items_attributes = self.items.map(&:attributes).map do |e|
        {
          id: e[:id],
          position: e[:position],
          parent_id: e[:parent_id],
        }
      end

      return self.update(items_attributes: items_attributes)
    end

    class Item < ::Dynamic::Base
      define_api_path # /api/d/uneek/r__menu__items

      translates :label
      globalize_accessors

      def initialize(json)
        super
        self.scope = { include: {translations: 1}}
      end

      def self.exceptions_for_update
        ['klass_name', 'action', 'parameters', 'layout']
      end

      attr_accessor :klass_name
      def klass_name
        @klass_name || self.class.extract_klass_name_from_link(self.link)
      end

      enum action: [:last_search]
      def action
        @action || self.class.extract_action_from_link(self.link)
      end

      def parameters
        @action || self.class.extract_parameters_from_link(self.link)
      end

      def layout
        @layout || self.class.extract_layout_from_link(self.link)
      end

      def sub_menu
        self.menu&.items&.select{|item| item.parent_id == self.id && !item.new_record?}&.sort_by{ |item| item.position || 0} || []
      end

      def parent
        self.menu&.item_by_id(self.parent_id)
      end

      def descendants
        return [] unless self.menu
        result = self.menu.items.select{|item| item.parent_id == self.id}
        result.each do |r|
          result.concat(self.menu.items.select{|item| item.parent_id == r.id})
        end
        return result
      end

      def self.extract_action_from_link(link)
        return unless link.present?
        link =~ /\/crm\/[^\/]+\/[^\/]+\/[^\/]+\/([^\/\?]+)/
        r = $1
        return self.actions.keys.include?(r) ? r : nil
      end

      def self.extract_klass_name_from_link(link)
        return unless link.present?
        link =~ /\/crm\/[^\/]+\/[^\/]+\/([^\/]+)/
        return $1
      end

      def self.extract_parameters_from_link(link)
        return unless link.present?
        link =~ /\/crm\/[^\/]+\/[^\/]+\/[^\/]+(?:\/[^\/\?]+)?\?(.*)/
        return $1
      end

      def self.extract_layout_from_link(link)
        return unless link.present?
        parameters = extract_parameters_from_link(link).to_s.split('&')
        return parameters.detect{|p| p.start_with?('l=')}&.gsub(/^l=/, '')
      end
    end

    class Relation < ::Dynamic::ReservedRelation
    end

    module Feature; extend ActiveSupport::Concern

      def self.load_constants(schema)
        menu_klass = schema.const_reserved_klass("Menu", ::Dynamic::Menu)
        menu_items_klass = schema.const_reserved_klass("Menu::Item", ::Dynamic::Menu::Item)

        menu_items_klass.belongs_to(:menu, class_name: menu_klass.name, inverse_of: :items)
        menu_klass.has_many(:items, class_name: menu_items_klass.name, inverse_of: :menu)
      end

    end

  end

end
