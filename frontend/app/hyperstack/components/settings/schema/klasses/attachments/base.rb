class Settings
  class Schema
    class Attachment
      class Base < ::Settings::Schema::Klasses::Base

        before_update do
          if schema_attachment&.not_found?
            App.history.push(attachments_location)
          end
        end

        def schema_attachment
          observe @schema_klass = Dynamic::Schema::Attachment::Base.where({
            schema_id: match.params['schema_id'],
            klass_id: match.params['klass_id'],
          }).find(match.params['attachment_id'])
        end

        def scope_for_all
          match.params.slice(:schema_id, :klass_id, :attachment_id)
        end

        def attachments_location
          "#{schema_location}/klasses/#{match.params['klass_id']}/attachments"
        end

        def back_location
          "#{attachments_location}/#{match.params['attachment_id']}"
        end

        def parent_page(params = {})
          attachment_page(params)
        end

        def attachment_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attachment.human_name, back: parent_back_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::Attachments.children_items(schema),
              location: back_location
            })
          end
        end

        def items
          items = []
          items << {id: 'variants', title: Dynamic::Schema::Attachment::Base.human_attribute_name('variants'), icon: 'crop-simple'}
          items
        end

        def new_record
          klass.new(klass_id: schema_klass.id)
        end

      end
    end
  end
end
