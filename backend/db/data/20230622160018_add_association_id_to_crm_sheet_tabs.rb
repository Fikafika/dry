# frozen_string_literal: true

class AddAssociationIdToCrmSheetTabs < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.layouts.with_action(:edit).find_each do |layout|
        klass = schema.klasses.detect{|e| e.name == layout.klass_name.demodulize}
        next unless klass
        layout.elements.where(component: 'Crm::Sheet::TabBar::Tab').find_each do |tab|
          params = tab.component_params
          next if params['name'] == 'all'
          assoc = klass.associations.detect{|a| a.name == params['name']}
          if assoc
            params['association_id'] = assoc.id
            tab.component_params = params
            tab.save if tab.changed?
          else
            tab.destroy
          end
        end
      end
    end
  end

  def down
  end
end
