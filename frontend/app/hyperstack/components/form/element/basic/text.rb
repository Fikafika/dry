class Form
  module Element
    module Basic
      class Text < Base
        render { content }

        #def render_readonly
          #if in_editor
            #DIV(ref: _ref, class: 'row') do
              #DIV(
                #class: 'col',
                #dangerously_set_inner_HTML: { __html: text },
                #style: { minHeight: '20px', display: 'block' },
              #) do
              #end
            #end
          #else
            #SPAN(dangerously_set_inner_HTML: { __html: text }) {}
          #end
        #end

        def render_readonly
          layout_readonly do
            SPAN(dangerously_set_inner_HTML: { __html: text }) {}
          end
        end

      end
    end
  end
end


