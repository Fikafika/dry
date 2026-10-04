class Settings
  class Schema
    class Attribute
      class Base < ::Settings::Schema::Klasses::Base

        before_update do
          if schema_attr&.not_found?
            App.history.push(attrs_location)
          end
        end

        def schema_attr
          observe @schema_klass = Dynamic::Schema::Attribute::Base.where({
            schema_id: match.params['schema_id'],
            klass_id: match.params['klass_id'],
          }).find(match.params['attr_id'])
        end

        def scope_for_all
          match.params.slice(:schema_id, :klass_id, :attr_id)
        end

        def attrs_location
          "#{schema_location}/klasses/#{match.params['klass_id']}/attributes"
        end

        def back_location
          "#{attrs_location}/#{match.params['attr_id']}"
        end

        def parent_page(params = {})
          attr_page(params)
        end

        def attr_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attr.human_name, back: parent_back_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::Attributes.children_items(schema),
              location: back_location
            })
          end
        end

        def items
          items = []
          items << {id: 'values', title: Dynamic::Schema::Validation::Base.human_attribute_name('values'), icon: 'list'} if schema_attr.type == 'Enum'
          items << {id: 'validations', title: Dynamic::Schema::Attribute::Base.human_attribute_name('validations'), icon: 'check-circle'}
          items << {id: 'sequences', title: Dynamic::Schema::Attribute::Base.human_attribute_name('sequences'), icon: 'arrow-down-1-9'} if schema_attr.type == 'String'
          items << {id: 'styles', title: I18n.t('settings.attributes.styles.title'), icon: 'fa fa-palette'} if schema&.has_feature_enabled?('Dynamic::Datatable::Style::Feature')
          items
        end

        def new_record
          klass.new(klass_id: schema_klass.id)
        end

      end
    end
  end
end
