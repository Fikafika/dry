class Settings
  class Schema
    class Features
      class Base < ::Settings::Schema::Base
        render{ content }

        def features_location
          "#{schema_location}/features"
        end

        def back_location
          "#{features_location}/#{match.params['feature_id']}"
        end

        def parent_back_location
          features_location
        end

        def parent_page(params = {})
          features_page(params)
        end

        def features_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_feature.human_name, back: parent_back_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::Features.children_items(schema),
              location: back_location
            })
          end
        end

        def schema_feature
          observe @schema_feature = Dynamic::Schema::Feature.includes({
            concern_templates: {
              include: {options: 1, translations: 1},
              concerns: 1
            }
          }).where(schema_id: match.params['schema_id']).find(match.params['feature_id'])
          @schema_feature
        end

      end
    end
  end
end