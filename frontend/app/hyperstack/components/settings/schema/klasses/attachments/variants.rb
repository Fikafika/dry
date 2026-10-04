class Settings
  class Schema
    class Attachment
      class Variants < Base

        render { content }

        def klass
          ::Dynamic::Schema::Attachment::Variant
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
            attachment_id: match.params['attachment_id'],
          })

        end

        def attachment_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attachment.human_name, back: attachments_location)
            end
            ::Stackable::List({
              active: 'variants',
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
            location: attachments_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id], klass_id: match.params[:klass_id]},
          )
        end

        def self.includes_for_all
          { include: { variants: 1 } }
        end

        def schema_klass
          observe @schema_klass = Dynamic::Schema::Klass.includes({attrs: {includes: {translations: 1}}}).where(schema_id: match.params['schema_id']).find(match.params['klass_id'])
        end

        def edit_panel
          EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema, schema_attachment: schema_attachment, schema_klass: schema_klass)
        end

        class EditPanel < ::Settings::Schema::EditPanel

          render { content }
          param :schema_attachment, default: nil

          def form
            Form(record: record) do
              Form::Element::Attribute::String(
                attribute_name: 'name',
                auto_focus: true,
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'resize_type',
              )
              Form::Element::Layout::Condition(resize_type: ['to_limit', 'to_fit', 'to_fill', 'and_pad']) do
                Form::Element::Attribute::Integer(
                  attribute_name: 'resize_width',
                )
                Form::Element::Attribute::Integer(
                  attribute_name: 'resize_height',
                )
              end
              Form::Element::Attribute::Boolean(
                attribute_name: 'crop',
              )
              Form::Element::Layout::Condition(crop: true) do
                Form::Element::Attribute::Integer(
                  attribute_name: 'crop_left',
                )
                Form::Element::Attribute::Integer(
                  attribute_name: 'crop_top',
                )
                Form::Element::Attribute::Integer(
                  attribute_name: 'crop_width',
                )
                Form::Element::Attribute::Integer(
                  attribute_name: 'crop_height',
                )
              end
              Form::Element::Attribute::Enum(
                attribute_name: 'format',
                placeholder: I18n.t('activerecord.values.dynamic/schema/attachment/variant.format.original')
              )
              Form::Element::Attribute::Integer(
                attribute_name: 'quality',
                placeholder: I18n.t('activerecord.attributes.dynamic/form/element/base.default_value'),
              )
              Form::Element::Attribute::String(
                attribute_name: 'attachment_id',
                editor: 'hidden',
              )
              comment
            end.on(:success) do
              App.history.push(record_location)
            end
          end

          def footer
            form_footer
          end

        end
      end
    end
  end
end
