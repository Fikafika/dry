class ::Settings::Layout < HyperComponent

  render(DIV) do
    LeftMenu()
    Toolbar(class:"toolbar bg-primary d-flex flex-row fixed-top align-items-center") do
      Toolbar::Button(text: '', icon_size: '2x', icon: 'bars', toggle: 'modal', target: "#left-menu", variant: 'primary')
      DIV(class: 'p-2 flex-fill') do
      end
      DIV() do
        Toolbar::UserButton(variant: 'primary')
      end
    end
    children.each(&:render)
  end

end
