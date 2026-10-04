class Settings
  class Schema
    module DocGen
      class Base < Klasses::Base

        def template_id
          match.params[:template_id]
        end

        def schema_klass_id
          match.params[:klass_id]
        end

        def template
          if schema.constants_loaded?
            observe schema.const::R::DocGen::Template.where(
              schema_id: match.params[:schema_id],
              klass_id: match.params[:klass_id],
            ).find(template_id)
          else
            nil
          end
        end

        def self.children_items(schema, template_klass)
          items = [
            {
              id: 'permissions',
              icon: 'user-lock',
              title: UneekPermission::Rule.model_name.human
            },
          ]
          if template_klass && (template_klass < schema.const::R::DocGen::Merge::Template)
            [
              schema.const::R::DocGen::Merge::File,
            ].each do |a|
              items << {
                id: resources_name(a),
                icon: a.icon,
                title: a.model_name.human(count: 2),
              }
            end
          end
          return items
        end

        def templates_location
          "#{schema_location}/klasses/#{schema_klass_id}/templates"
        end

      end
    end
  end
end