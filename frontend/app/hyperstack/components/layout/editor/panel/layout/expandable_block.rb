class Layout
  class Editor
    module Panel
      module Layout
        module ExpandableBlock
          class Base < Panel::Base
            collect_other_params_as :other_params

            render { content }

            def parameters
              title_parameter
            end

            def title_parameter
              ::Form::Element::Attribute::String(
                attribute_name: 'title',
                label: 'Titre'
              )
            end
          end
        end
      end
    end
  end
end
