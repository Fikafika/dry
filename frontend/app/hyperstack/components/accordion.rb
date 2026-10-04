require 'active_support'
require 'active_support/concern'
require 'components/hyper_component'

class Accordion < HyperComponent
  param :title, default: nil
  param :is_open, default: false
  param :style, default: nil
  param :is_last, default: false

  before_mount do
    @open_state = is_open
  end

  def toggle_accordion
    mutate @open_state = !@open_state
  end

  render { content }

  def content
    DIV(style: style, class: "border-top#{' border-bottom mb-3' if is_last}") do
      A(
        href: "##{title}",
        class: "btn shadow-none p-2 w-100 text-left",
        style: {cursor: "pointer"},
        'aria-expanded': @open_state.to_s,
      ) do
        I(class: "fa-fw fas #{@open_state ? 'fa-chevron-down' : 'fa-chevron-right'} pr-2")
        title
      end.on(:click) do |e|
        e.prevent_default
        toggle_accordion
      end
      DIV(class: "accordion-collapse collapse #{@open_state ? 'show border-top': 'hide'}") do
        DIV(class: 'pt-3 px-3') do
          children.each { |child| child.render }
        end
      end
    end
  end
end