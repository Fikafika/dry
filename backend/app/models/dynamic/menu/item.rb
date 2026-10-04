module Dynamic
  class Menu
    class Item < ActiveRecord::Base
      self.abstract_class = true

      include Dynamic::Mount

      define_table do |t|
        t.string :label, translate: true
        t.text :link
        t.string :icon
        t.integer :position
        t.belongs_to :menu, type: :uuid
        t.belongs_to :parent, type: :uuid
      end

      after_mount do
        belongs_to :menu, class_name: 'Menu', inverse_of: :items, touch: true
        belongs_to :parent, class_name: 'Item', optional: true, inverse_of: :items
        has_many :items, class_name: 'Item', inverse_of: :parent, dependent: :destroy
        accepts_nested_attributes_for :items, allow_destroy: true
      end

      def permitted
        klass_name = klass_name_from_link
        return true if klass_name.nil?
        klass = klass_name.safe_constantize
        return true if klass.nil? || !klass.include?(::UneekPermission::ControlledKlass) || menu.user.admin?(klass.module_parent.name.demodulize)
        return klass.can_be_read_by?(menu.user)
      end

      def klass_name_from_link
        return unless link.present?
        link =~ /\/crm\/([^\/]+)\/[^\/]+\/([^\/]+)/
        begin
          klass = "D::#{$1.classify_permalink}".safe_constantize.const_get_by_route_key($2)
        rescue NameError
          return nil
        end
        return klass&.name
      end

      concerning :Permissions do
        included do
          include UneekPermission::ControlledKlass

          def associations_for_uneek_permissions
            nil
          end
        end
      end
    end
  end
end
