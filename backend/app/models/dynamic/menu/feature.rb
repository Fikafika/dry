module Dynamic
  class Menu
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Menus dynamiques',
          human_name_en: 'Dynamic menus',
          mandatory: true,
        }
      end

      def self.load(schema)
        Dynamic::Menu.mount(schema)
        Dynamic::Menu::Item.mount(schema)
      end

    end
  end
end
