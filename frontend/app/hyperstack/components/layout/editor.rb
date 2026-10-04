# backtick_javascript: true

class Layout
  class Editor < HyperComponent

    param :schema_id, default: nil
    param :klass_id, default: nil
    param :layout_id, default: nil

    collect_other_params_as :other_params

    def init
      @dragged_from = nil
      @selected_element ||= nil
      @active_chevron ||= 'active'
      @active_local_chevron ||= []
      @changes ||= Set.new
      @state_elements ||= {}
      @over_elements ||= {}
      @roading_tree = []
    end

    def layout
      observe Dynamic::Layout.includes(elements: 1).where(schema_id: schema_id).find(layout_id)
    end

    before_mount do
      init
      component_treatement(components_klasses)
    end

    render do
      DIV(class: 'form-editor w-100 h-100') do
        DIV(class:'form-editor-top p-2 bg-light border-bottom') do
          BUTTON(class: 'btn btn-light') do
            SPAN(class: 'fa fa-chevron-left fa-fw') do
            end
            I18n.t('shared.back')
          end.on(:click) do
            App.history.push(request.location.pathname.gsub(/\/edit$/, ''))
          end
        end
        DIV(class: 'form-editor-left-panel overflow-auto border-right bg-light p-2') do
          DIV do
            UL do
              LI do
                DIV(class: 'd-flex item pr-2 w-100') do
                  DIV(class: "d-inline d-tree-toggler m-auto #{@active_chevron}") do
                    SPAN(class: 'arrow float-left fas fa-chevron-right fa-xs pr-1') do
                    end
                  end
                  DIV(class: 'form-editor-list-not-draggable w-100') do
                    I18n.t('layout_editor.components')
                  end
                end.on(:click) do |evt|
                  evt.prevent_default
                  if @active_chevron == 'active'
                    @active_chevron = ''
                  else
                    @active_chevron = 'active'
                  end
                  mutate
                end
                if @active_chevron == 'active'
                  DIV(class: 'd-tree-content') do
                    UL(class: 'd-flex d-tree-container flex-column') do
                      UL do
                        tree_building(@base_tree)
                      end
                    end
                  end
                end
              end
            end
          end
        end
        DIV(class: 'form-editor-center-panel overflow-auto') do
          DIV(class: 'w-100 h-100') do
            DIV(class: 'h-100 overflow-auto border-bottom') do
              tree
            end
          end
        end
        DIV(class: 'form-editor-element-editor overflow-auto border-left bg-light') do
          DIV(class: 'overflow-auto w-100') do
            DIV do
              SPAN do
                DIV do
                  right_panel
                end
              end
            end
          end
        end
        DIV(class: 'form-editor-right-panel btn-toolbar justify-content-end p-2 border-left bg-light') do
          DIV do
            BUTTON(class: 'btn btn-light mr-2') do
              I18n.t('shared.cancel')
            end.on(:click) do
              layout.reload do
                reset
                mutate
              end
            end
            BUTTON(class: "btn btn-primary #{'disabled' if @saving}") do
              I18n.t('shared.save')
            end.on(:click) do
              save_button_on_click
            end
          end
        end
      end
    end

    def reset
      @dragged_from = nil
      @selected_element = nil
      @active_chevron = nil
      @changes = Set.new
    end

    def schema
      observe Dynamic::Schema.includes(Dynamic::Schema.includes_for_load).where(name: schema_id.classify_permalink).first
    end

    def components_klasses
      return @components_klasses if @components_klasses
      @components_klasses = [
        "DIV",
        "BUTTON",
      ]
      components = HyperComponent.descendants.map(&:name) - component_blacklist
      @components_klasses.concat(components)
      @components_klasses = @components_klasses.sort
      @components_klasses
    end

    def component_blacklist
      ['App', 'Layout::Editor', 'Test']
    end

    def tree
      return unless layout.loaded?
      DIV(class: 'd-flex flex-column w-100 h-100') do
        drop_zone('top')
        layout.root_elements.sort_by{|e| [(e.position || 1), e.id]}.each do |root|
          DIV(class: '', style: {opacity: 1}) do
            UL(class: 'pl-0 mb-0', style: {listStyleType: 'none', minWidth: "70%"}) do
              tree_node(root)
            end
          end
        end
        drop_zone('bottom')
      end
    end

    def tree_node(elem)
      @lock = false
      LI(class: "pb-1 #{@over_elements[elem.id] == 'over' ? 'border border-2 rounded border-primary' : '' } ", id: elem.id) do
        render_element(elem)
        UL(class: 'mb-0', style: {listStyleType: 'none'}) do
          if @state_elements[elem.id] != 'closed'
            elem.children.sort_by{|e| [(e.position || 0), e.id]}.each do |child|
              tree_node(child)
            end
          end
        end
      end.on(:drag_exit) do |evt|
        @over_elements.keys.each do |k|
          @over_elements[k] = ""
        end
        mutate
      end.on(:drag_enter) do |evt|
        if !@lock
          @over_elements.keys.each do |k|
            @over_elements[k] = ""
          end
          @over_elements[evt.current_target.id] = 'over'
          mutate
        end
        @lock = true
      end
    end

    def render_element(elem)
      if elem == @selected_element
        active = 'active'
      else
        active = ''
      end
      DIV(class: 'd-flex item pr-2 pb-1 w-100') do
        if @state_elements[elem.id] == "closed"
          active_chevron_2 = 'fa-chevron-right'
        else
          active_chevron_2 = 'fa-chevron-down'
        end
        DIV(class: 'd-inline d-tree-toggler d-flex active') do
          BUTTON(class: 'btn btn-transparent-light-yiq h-100') do
            SPAN(class: "arrow float-left fas #{active_chevron_2} fa-fw fa-xs pr-1") do
            end
          end.on(:click) do
            if @state_elements[elem.id] == "closed"
              @state_elements[elem.id] = "opened"
            else
              @state_elements[elem.id] = "closed"
            end
            mutate
          end
        end
        DIV(class: 'form-editor-list-draggable', draggable: 'true') do
          DIV(class: "p-2 layout-editor-item #{active}") do
            elem.component
          end
        end.on(:click) do |evt|
          evt.prevent_default
          if @selected_element == elem
            @selected_element = nil
          else
            @selected_element = elem
          end
          mutate
        end
      end.on(:drop) do |evt|
        evt.prevent_default
        case @dragged_from
        when 'left'
          new_element(elem, elem.children.length)
        when 'middle'
          unless elem.ancestors.include?(@component_dragged)
            if elem.parent.id != @component_dragged.parent.id
              parent = @component_dragged.parent
              parent_children = parent ? parent.children : layout.root_elements
              parent_children.delete(@component_dragged)
              @component_dragged.position = elem.children.length
              elem.children << @component_dragged
              @component_dragged.parent_id = elem.id
              @changes << @component_dragged
            end
          end
        end
        @dragged_from = nil
        @component_dragged = nil
        mutate
      end.on(:drag_start) do |evt|
        @component_dragged = elem
        @dragged_from = "middle"
      end.on(:drag_over, &:prevent_default)
    end

    def new_element(parent, position)
      parent_id = parent&.id
      component = @component_dragged&.component
      component_params_converter_type = ::Layout::ParamsConverter.converters_for[component]&.first
      e = Dynamic::Layout::Element.new(
        id: Dynamic::Layout::Element.generate_uuid,
        component: component,
        component_params: {},
        parent_id: parent_id,
        layout_id: layout_id,
        position: position,
        component_params_converter_type: component_params_converter_type,
      )
      e.persisted = false
      e.layout = layout
      layout.elements_by_id[e.id] = e
      parent_children = parent ? parent.children : layout.root_elements
      parent_children << e
      modify_positions(parent_children, e, 1)
      @changes << e
    end

    def build_elements(elements_attributes, parent = nil)
      elements_attributes&.each_with_index do |element_attributes, i|
        build_element(element_attributes, i, parent)
      end
    end

    def build_element(attributes, position = nil, parent = nil)
      parent_id = parent&.id
      e = Dynamic::Layout::Element.new(
        {
          component_params: {},
          component_params_converter_options: {}
        }.merge(
          attributes.except(:children_attributes)
        ).merge({
          id: Dynamic::Layout::Element.generate_uuid,
          parent_id: parent_id,
          layout_id: layout_id,
          position: position,
        })
      )
      e.persisted = false
      e.layout = layout
      layout.elements_by_id[e.id] = e
      parent_children = parent ? parent.children : layout.root_elements
      parent_children << e
      modify_positions(parent_children, e, 1)
      @changes << e
      build_elements(attributes[:children_attributes], e)
    end


    def drop_zone(drop_zone_position = nil)
      DIV(class: "w-100 #{'flex-grow-1' if drop_zone_position == 'bottom'}", style: {minHeight: '15px'}) do
        ''
      end.on(:drop) do |evt|
        position = drop_zone_position == 'top' ? 0 : layout.root_elements.length

        case @dragged_from
        when 'left'
          new_element(nil, position)
        when 'middle'
          if layout.root_elements.include? @component_dragged
            modify_positions(layout.root_elements, @component_dragged, -1)
            @component_dragged.position = position
          else
            previous_parent_children = layout.elements_by_parent_id[@component_dragged.parent_id]
            modify_positions(previous_parent_children, @component_dragged, -1)
            previous_parent_children.delete(@component_dragged)
            @component_dragged.parent_id = nil
            layout.root_elements << @component_dragged
            @component_dragged.position = position
            if position == 0
              modify_positions(layout.root_elements, @component_dragged, 1)
            end
          end
          @changes << @component_dragged
        end
        @component_dragged = nil
        @dragged_from = nil
        after(0.1) { scroll(drop_zone_position) } if drop_zone_position
        mutate
      end.on(:drag_over, &:prevent_default)
    end

    def scroll(position)
      e = self.jq_node.find('.form-editor-center-panel .overflow-auto')
      t = position == 'top' ? 0 : e.height
      e.animate(scrollTop: t)
    end

    def save_button_on_click
      mutate @saving = true
      layout.update(elements_attributes: element_attributes).then do
        @changes.each do |c|
          next if c.deleted_at.present?
          c.persisted = true
        end
        @saving = false
        reset
        mutate
      end
    end

    def element_attributes
      result = []
      @changes.each do |k|
        attrs = {
          component: k.component,
          component_params: k.component_params,
          component_params_converter_type: k.component_params_converter_type,
          component_params_converter_options: k.component_params_converter_options,
          layout_id: layout_id,
          id: k.id,
          parent_id: k.parent_id,
          position: k.position,
        }
        attrs[:_destroy] = '1' if k.deleted?
        result << attrs
      end
      return result
    end

    def replace_elements_of_selected_element(elements_attributes)
      selected = @selected_element
      delete_elements(selected.children)
      if elements_attributes.class == Proc
        elements_attributes = elements_attributes.call(selected)
      end
      build_elements(elements_attributes, selected)
      mutate
    end

    def right_panel
      right_panel_class&.create_element(
        layout: layout,
        element: @selected_element,
        delete_element: delete_element_proc,
        schema: schema,
        replace_elements_of_selected_element: method(:replace_elements_of_selected_element),
      ).on(:change) do
        @changes << @selected_element if @selected_element
      end.on(:reload) do
        mutate
      end
    end

    def right_panel_class
      if @selected_element
        result = "#{self.class.name}::Panel::#{@selected_element&.component.to_s}::Base".safe_constantize
        result = "#{self.class.name}::Panel::#{@selected_element&.component.to_s.gsub('Form', 'Forms')}::Base".safe_constantize unless result
        result = self.class::Panel::Base unless result
      else
        result = self.class::Panel::Empty::Base
      end
      return result
    end

    def delete_elements(elements)
      elements.reverse_each do |element|
        delete_element(element)
      end
    end

    def delete_element(element)
      ([element] + element.descendants.to_a).each do |c|
        if c.persisted || c.persisted == nil # persisted is nil when retrieving element from db
          c.deleted_at = DateTime.now
          @changes << c
        else
          @changes.delete(c)
        end
        layout.elements_by_parent_id[c.parent_id]&.delete(c)
      end

      if element == @selected_element
        @selected_element = nil
      end
    end

    def delete_element_proc
      return Proc.new do |element|
        delete_element(element)
        mutate
      end
    end

    def modify_positions(array, component, inc)
      if component.position
        array.each do |e|
          next unless e.position && e != component && e.position >= component.position
          e.position += inc
          @changes << e
        end
      end
      return array
    end

    def component_treatement(components_list)
      @base_tree = {}
      components_list.each do |component|
        splited_component = component.split('::')
        current = @base_tree
        splited_component.each do |splited_one|
          unless current.keys.include? splited_one
            current[splited_one] = {}
          end
          current = current[splited_one]
        end
      end
    end

    def tree_building(reference_tree)
      if reference_tree && reference_tree.is_a?(Hash)
        reference_tree.keys.each do |key|
          @roading_tree.push(key.to_s)
          if !reference_tree[key].keys.empty?
            item_chevron = @active_local_chevron.find { |f| f["element"] == @roading_tree.join('::')}
            unless item_chevron
              @active_local_chevron.push({"element" => @roading_tree.join('::'), "active_chevron" => ''})
              item_chevron = @active_local_chevron.find { |f| f["element"] == @roading_tree.join('::')}
            end
            DIV(class: 'd-flex item pr-2 w-100') do
              DIV(class: "d-inline d-tree-toggler m-auto", id: "#{@roading_tree.join('::')}") do
                SPAN(class: "arrow float-left fas #{item_chevron["active_chevron"] == "active" ? "fa-chevron-down" : "fa-chevron-right"} fa-xs pr-1") do
                end
              end
              DIV(class: 'form-editor-list-draggable w-100', draggable: 'true', id: "#{@roading_tree.join('::')}") do
                key
              end.on(:drag_start) do |evt|
                  @component_dragged = Dynamic::Layout::Element.new(component: evt.target.id)
                  @dragged_from = "left"
              end
            end.on(:click) do |evt|
              evt.prevent_default
              if item_chevron["active_chevron"] == 'active'
                item_chevron["active_chevron"] = ''
              else
                item_chevron["active_chevron"] = 'active'
              end
              mutate
            end
            if item_chevron["active_chevron"] == 'active'
              DIV(class: 'd-tree-content ml-2') do
                UL(class: 'd-flex d-tree-container flex-column') do
                  tree_building(reference_tree[key])
                end
              end
            end
            @roading_tree.pop
          else
            LI do
              DIV(class: 'd-flex item pr-2 w-100') do
                DIV(class: 'form-editor-list-draggable w-100', draggable: 'true', id: "#{@roading_tree.join("::")}") do
                  key
                end.on(:drag_start) do |evt|
                  @component_dragged = Dynamic::Layout::Element.new(component: evt.target.id)
                  @dragged_from = "left"
                end
              end
            end
            @roading_tree.pop
          end
          if @base_tree.keys.last == key
            @roading_tree.pop
          end
        end
      end
    end
  end
end
