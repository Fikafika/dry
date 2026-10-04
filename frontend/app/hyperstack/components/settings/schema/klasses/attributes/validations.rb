require 'components/settings/schema/klasses/validations'
class Settings
  class Schema
    class Attribute
      class Validations < Attribute::Base

        render { content }

        def klass
          ::Dynamic::Schema::Validation::Base
        end

        def current_model # TODO fix record loading in order to store klass_id
          m = super
          return unless m
          m.attributes['klass_id'] ||= match.params['klass_id']
          m
        end

        def new_record
          klass.new({
            schema_id: match.params['schema_id'],
            klass_id: match.params['klass_id'],
            attr_id: match.params['attr_id'],
          })

        end

        def attr_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attr.human_name, back: attrs_location)
            end
            ::Stackable::List({
              active: 'validations',
              items: items,
              location: back_location
            })
          end
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Schema::Attribute::Base,
            resource_id_key: :attr_id,
            path_prefix: path_prefix,
            location: attrs_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id], klass_id: match.params[:klass_id]},
          )
        end

        def self.includes_for_all
          { include: { validation: {include: {translation: 1}} } }
        end

        def schema_klass
          observe @schema_klass = Dynamic::Schema::Klass.includes({attrs: {includes: {translations: 1}}}).where(schema_id: match.params['schema_id']).find(match.params['klass_id'])
        end

        def edit_panel
          EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema, schema_attr: schema_attr, schema_klass: schema_klass)
        end

        class EditPanel < ::Settings::Schema::Validations::EditPanel

          render { content }
          param :schema_attr, default: nil

          def additional_fields
            Form::Element::Attribute::String(
              attribute_name: 'attr_id',
              editor: 'hidden',
            )
            Form::Element::Attribute::String(
              attribute_name: 'attr_type',
              value: schema_attr.type,
              editor: "hidden"
            )
          end
        end
      end
    end
  end
end
