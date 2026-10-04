require 'components/form/element/base'

class Form
  module Element
    module Layout
      class Base < ::Form::Element::Base

        render {}

        private

        def children_render
          if !in_editor && self.form
            children.each  do |c|
              self.form&.render_child(c, prefix_path, record, conditions, in_hash)
            end
          else
            children.render
          end
        end

      end
    end
  end
end
