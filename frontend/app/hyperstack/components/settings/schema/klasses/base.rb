class Settings

  class Schema

    class Klasses

      class Base < ::Settings::Schema::Base

        before_update do
          if schema_klass&.not_found?
            App.history.push(klasses_location)
          end
        end

        def schema_klass
          observe @schema_klass = Dynamic::Schema::Klass.includes(Settings::Schema::Klasses.includes_for_show).where(schema_id: match.params['schema_id']).find(match.params['klass_id'])
        end

        def scope_for_all
          match.params.slice(:schema_id, :klass_id)
        end

        def klasses_location
          "#{schema_location}/klasses"
        end

        def back_location
          "#{klasses_location}/#{match.params['klass_id']}"
        end

        def parent_page(params = {})
          klass_page(params)
        end

        def klass_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_klass.human_name, back: parent_back_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::Klasses.children_items(schema, schema_klass),
              location: back_location
            })
          end
        end

        def parent_back_location
          klasses_location
        end

        def new_record
          klass.new(klass_id: schema_klass.id)
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Schema::Klass,
            resource_id_key: :klass_id,
            path_prefix: path_prefix,
            location: klasses_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id]},
            includes_for_all: { include: { translations: 1 } },
            schema: schema,
          )
        end

        def schema_klass_name
          "D::#{match.params['schema_id'].classify_permalink}::#{match.params['klass_id'].camelize}"
        end

        module RecomputeFormulaMenuItem; extend ActiveSupport::Concern

          def item_recompute_formula
            A(href: '#', class: 'dropdown-item text-capitalize-first-letter') do
              I18n.t('settings.klasses.attributes.recompute_formula')
            end.on(:click) do |event|
              event.prevent_default
              Modal.confirm(title: I18n.t('settings.klasses.attributes.recompute_formula')) do
                current_model.recompute_formula
              end
            end
          end

        end

        module ItemIconAssigner
          def attach_icons_to_item(model, item)
            item[:icons] ||= []
            item[:icons] += assign_icons(model)
            item
          end

          def assign_icons(model)
            icons = []
            icon_attributes_by_type.map do |attribute, data|
              icons << data if model&.try(attribute).present?
            end
            icons
          end

          def icon_attributes_by_type
            {
              formula: { icon: 'fa fa-calculator', tooltip: I18n.t('activerecord.defaults.attributes.item_calculated') }
            }
          end
        end
      end

    end

  end

end
