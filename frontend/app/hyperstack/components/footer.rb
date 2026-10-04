class Footer < HyperComponent

  collect_other_params_as :other_params

  render() do
    DIV(class: other_params[:className], style: other_params[:style]) do
      children.each(&:render)
    end
  end

end
