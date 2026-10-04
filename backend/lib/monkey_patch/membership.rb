ActiveSupport.on_load(:membership) do

  concerning :CreateDynamicMenu do
    included do
      after_create :create_dynamic_menu

      def create_dynamic_menu
        return unless self.community.schema

        Dynamic::Schema.load(self.community.schema.name) do |s|
          return unless "#{s.const.name}::R::Menu".safe_constantize

          item_attributes = []
          s.klasses.sort_by { |k| k.human_name.to_s }.each_with_index do |k, i|
            attrs = k.dynamic_menu_item_attributes.merge!(position: i)
            item_attributes << attrs
          end

          menu = s.const::R::Menu.create_with(
            human_name: 'CRM',
            items_attributes: item_attributes,
          ).find_or_create_by!(
            user_id: self.user_id,
            name: 'crm',
          )
        end
      end

      def recreate_dynamic_menu # for maintenance
        Dynamic::Schema.load(self.community.schema.name) do |s|
          return unless "#{s.const.name}::R::Menu".safe_constantize
          s.const::R::Menu.where(user_id: self.user_id).destroy_all
        end
        create_dynamic_menu
      end

    end
  end

end
