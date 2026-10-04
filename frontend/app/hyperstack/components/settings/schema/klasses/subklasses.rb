class Settings
  class Schema
    class Klasses

      class Subklasses < Base

        render { content }

        def self.icon
          'folder-tree'
        end

        def self.resources_name(klass = self, plural = false)
          'subklasses'
        end

        def list_page
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: I18n.t('settings.klasses.subklasses'), back: back_location)
            end
            ::Stackable::List(
              active: nil,
              items: subklass_items,
              location: klasses_location,
            )
          end
        end

        def subklass_items
          return [] unless schema_klass&.id
          schema.klasses.select{|k| k.superklass_id == schema_klass.id}.sort_by{|k| k.human_name.to_s }.map do |k|
            {
              id: Dynamic::Schema::Klass.api_id(k),
              icon: k.icon.presence || 'table',
              title: k.human_name,
            }
          end
        end

      end

    end
  end
end
