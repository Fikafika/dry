# frozen_string_literal: true

class AddEditIconToCrmSheetItems < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.layouts.with_action(:edit).find_each do |layout|
        layout.elements.where(component_params_converter_type: 'Crm::Sheet::TabBar::Tab::InfiniteScrollerParamsConverter').find_each do |scroller|
          ::Dynamic::Layout::Element.descendants_of_record(scroller).where(component: 'Crm::Sheet::Item').find_each do |item|
            next if ::Dynamic::Layout::Element.descendants_of_record(item.parent.parent).where(component_params_converter_type: 'Crm::Sheet::Item::EditIconParamsConverter').exists?
            item.parent.parent.children.create!({
              component: 'DIV',
              component_params: {},
              children_attributes: [{
                component: 'IconButton',
                component_params: {},
                component_params_converter_type: 'Crm::Sheet::Item::EditIconParamsConverter',
              }],
              position: 1
            })
            item.update!(position: 0)
            item.parent.parent.children.where(component: 'Crm::Sheet::Item::Menu').first.update!(position: 2)
          end
        end
      end
    end
  end

  def down
  end
end
