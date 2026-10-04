module Dynamic
  class Menu < ActiveRecord::Base
    self.abstract_class = true

    include Dynamic::Mount

    define_table do |t|
      t.string :name
      t.string :human_name, translate: true
      t.belongs_to :user, type: :uuid
    end

    after_mount do
      has_many :items, class_name: 'Item', inverse_of: :menu, dependent: :destroy
      accepts_nested_attributes_for :items, allow_destroy: true
      belongs_to :user, optional: true
      validates :name, uniqueness: { scope: :user_id }
    end

    def copy_to_users(users, merge: false)
      user_ids = users.map(&:id)
      return false unless user_ids.any?
      menu_ids = self.class.where(user_id: user_ids, name: self.name).pluck(:id)
      return false unless menu_ids

      items_attrs = []
      items_translations_attrs = []

      self.class::Item.where(menu_id: self.id).includes(translations: {}).each do |i|
        items_attrs << i.attributes.slice('id', 'link', 'icon', 'position', 'parent_id')
        i.translations.each do |t|
          items_translations_attrs << t.attributes.slice('id', 'owner_id', 'label', 'locale')
        end
      end

      return false unless items_attrs.any?

      unless merge
        item_ids = self.class::Item.where(menu_id: menu_ids).pluck(:id)
        self.class::Item::Translation.where(owner_id: item_ids).delete_all
        self.class::Item.where(menu_id: menu_ids).delete_all
      end

      new_items_attrs = []
      new_items_translations_attrs = []

      menu_ids.each do |menu_id|
        new_uuids = {}

        items_attrs.each do |i|
          new_uuids[i['id']] ||= UUID7.generate
          new_uuids[i['parent_id']] ||= UUID7.generate if i['parent_id']
          new_items_attrs << i.merge(
            'id' => new_uuids[i['id']],
            'parent_id' => new_uuids[i['parent_id']],
            'menu_id' => menu_id,
          )
        end
        items_translations_attrs.each do |t|
          new_uuids[t['id']] ||= UUID7.generate
          new_uuids[t['owner_id']] ||= UUID7.generate
          new_items_translations_attrs << t.merge(
            'id' => new_uuids[t['id']],
            'owner_id' => new_uuids[t['owner_id']],
          )
        end
      end

      self.class::Item.import(new_items_attrs)
      self.class::Item::Translation.import(new_items_translations_attrs)

      self.class.where(id: menu_ids).touch_all

      return true
    end

    def sort_items_by_alphabetical_order
      items_attributes = []
      current_parent_id = nil
      position = -1
      items.includes(translations: {}).where(parent_id: nil).sort_by{|item| [item.parent_id, item.label]}.each do |item|
        if current_parent_id != item.parent_id
          position = -1
          current_parent_id = item.parent_id
        end
        position += 1
        items_attributes << {id: item.id, position: position}
      end
      update(items_attributes: items_attributes)
    end

    def self.remove_duplicated_menus(do_it = true) # for maintenance
      user_ids = self.pluck('user_id').uniq
      to_destroy = []
      user_ids.each do |user_id|
        self.where(user_id: user_id).select(:id, :name).group_by(&:name).each do |name, menus|
          if menus.length > 1
            to_destroy.concat(menus.sort_by(&:id)[1..-1].map(&:id))
          end
        end
      end
      unless do_it
        puts "menus to destroy :"
        menus = self.where(id: to_destroy).all
        pp menus
        return menus
      else
        return self.where(id: to_destroy).destroy_all
      end
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
