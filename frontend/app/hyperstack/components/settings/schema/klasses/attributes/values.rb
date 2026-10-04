class Settings
  class Schema
    class Attribute
      class Values < Attribute::Base

        render { content }

        def klass
          ::Dynamic::Schema::Attribute::Enum::Value
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
              active: 'values',
              items: items,
              location: back_location
            })
          end
        end

        def resource_id_key
          :value_id
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

        def parent_parent_location_suffix
          ''
        end

        class EditPanel < ::Settings::Schema::EditPanel

          render { content }

          def form
            Form(record: record) do
              Form::Element::Attribute::TranslatableString(
                attribute_name: 'human_name',
                errors_from: 'name',
                help: record.new_record? ? '' : I18n.t('activerecord.defaults.attributes.variable_name_text', variable_name: record.name),
                auto_focus: true,
              )
              comment
              Form::Footer()
            end.on(:success) do
              App.history.push(record_location)
            end
          end

        end
      end
    end
  end
end
