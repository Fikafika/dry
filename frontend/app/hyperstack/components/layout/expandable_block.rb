require 'components/layout'

class Layout::ExpandableBlock < Layout::Element
## ATTENTION intégrer un systeme d'index pour avoir des data target uniques afin que cela fonctionne correctement.
  collect_other_params_as :other_params
  param :title, default: nil

  render {content}

  def content
    DIV(class: "expandable-block card mb-2") do
      DIV(class: "card-header align-items-center d-flex flex-row p-0") do
        A(class: "btn", "data-toggle": "collapse", href: "##{css_id}", role: "button", "aria-expanded": "false", "aria-controls": "#{css_id}") do
          SPAN(class: "expandable-block-chevron fa-solid fa-chevron-right") {}
        end
        DIV(class: "pl-1") do
          title if title
        end
      end

      DIV(class: "collapse expandable-block-card-body card-body pt-0 overflow-auto", id: "#{css_id}") do
        super { children.render }
      end
    end
  end

  def css_id
    @css_id ||= "expandable-block-#{@@expandable_block_count ||= 0; @@expandable_block_count += 1}"
  end
end
