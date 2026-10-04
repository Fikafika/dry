class ExpandingSideBar < HyperComponent

  param :offset, default:'', type: String

  collect_other_params_as :other_params

  render() do
    DIV(class: "expanding-side-bar depth-0 #{other_params[:className]}") do
      children.render
    end.on(:mouse_enter) do
      after(0.5) do
        if ::Element.find(self.dom_node).find('.depth-0:hover').length > 0
          ::Element.find(self.dom_node).add_class('hover')

          after(transition_duration) do
            if ::Element.find(self.dom_node).find('.depth-0:hover').length > 0
              ::Element.find(self.dom_node).add_class('expanded')
            end
          end

        end
      end
    end.on(:mouse_leave) do
      if ::Element.find(self.dom_node).find('.depth-0:hover').length == 0
        ::Element.find(self.dom_node).remove_class('expanded')
        after(transition_duration) do
          if ::Element.find(self.dom_node).find('.depth-0:hover').length == 0
            ::Element.find(self.dom_node).remove_class('hover')
          end
        end
      end
    end
  end

  def transition_duration
    0.3 # TODO extract from css
  end

end
