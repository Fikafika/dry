# backtick_javascript: true

class Crm
  class Import
    class AttributesDropdown < HyperComponent

      param :klass
      param :path
      param :show_root_number, default: true
      before_mount :attach_event_dropdown_js
      before_unmount :detach_event_dropdown_js

      fires :change
      render() do
        k = klass
        if path&.any?
          assoc = nil
          path.each_with_index do |e, i|
            next if !show_root_number && (i == 0 && e.is_a?(Integer))
            if e.is_a?(Integer)
              if assoc.nil? || assoc&.collection?
                SPAN do
                  INPUT(type: 'number', min: 1, value: e + 1, style:{ width: '4em'}, class: "btn btn-light rounded-0 border-0").on(:change) do |event|
                    path[i] = event.target.value.to_i - 1
                    mutate
                    @current_path = path
                    change!(@current_path, @previous_path)
                  end
                end
              end
            else
              SPAN(class: 'dropdown multilevel-dropdown') do
                A(href:"#", class: 'btn btn-light rounded-0 border-0 dropdown-toggle', 'data-toggle': 'dropdown', 'aria-haspopup': 'true', 'aria-expanded': 'false', 'data-display': 'static') do
                  k.human_attribute_name(e)
                end.on(:click) do |evt|
                  @render_dropdown_method_menu = true
                  mutate
                end
                UL(class: 'dropdown-menu p-0 scrollable-menu') do
                  if @render_dropdown_method_menu
                    Crm::Import::RenderDropdownMenu(klass: k, association: assoc, path: path, association_path: path[0..i]).on(:change) do |current_path, previous_path|
                      change!(current_path, previous_path)
                    end
                  end
                end
              end
            end

            if i != path.size - 1 && !path[i + 1].is_a?(Integer)
              I(class: 'mx-1 align-self-center fa fa-xs fa-chevron-right fa-fw')
            end
            next if e.is_a?(Integer)
            assoc = k.reflect_on_association(e)
            break unless assoc
            k = assoc.klass
          end
        else
          DIV(class: 'dropdown multilevel-dropdown') do
            DIV(class: 'drop') do
              A(href:"#", class: 'btn btn-light rounded-0 border-0 dropdown-toggle', 'data-toggle': 'dropdown', 'aria-haspopup': 'true', 'aria-expanded': 'false', 'data-display': 'static') do
                I18n.t("shared.select")
              end.on(:click) do |evt|
                @render_dropdown_method_menu = true
                mutate
              end
              UL(class: 'dropdown-menu container p-0') do
                if @render_dropdown_method_menu
                  Crm::Import::RenderDropdownMenu(klass: klass, association: nil, path: path, association_path: [0]).on(:change) do |current_path, previous_path|
                    change!(current_path, previous_path)
                  end
                end
              end
            end
          end
        end
      end

      def attach_event_dropdown_js
        @original_body_styles ||= {}
        body_elements = ::Element.find('html, body')
        unless @original_body_styles[:initialized]
          @original_body_styles[:overflow] = body_elements.css('overflow').to_s
          @original_body_styles[:initialized] = true
        end
        Document.on('shown.bs.dropdown') do |event|
          body_elements.css(overflow: 'hidden') unless body_elements.css('overflow').to_s == 'hidden'
        end
        Document.on('hidden.bs.dropdown') do |event|
          body_elements.css(overflow: @original_body_styles[:overflow])
        end
      end

      def detach_event_dropdown_js
        ::Element.find('body').off('shown.bs.dropdown')
        ::Element.find('body').off('hidden.bs.dropdown')
      end

    end


    class RenderDropdownMenu < HyperComponent

      param :klass
      param :path
      param :association
      param :association_path

      fires :change

      render { content }

      def content
        if association.nil?
          LI() do
            A(href:"#", class: 'dropdown-item', dangerously_set_inner_HTML: {__html: '&nbsp;'}) do
            end.on(:click) do |evt|
              evt.prevent_default
              @previous_path = @current_path || path
              @current_path = []
              mutate
              change!(@current_path, @previous_path)
            end
          end
        end
        attributes.each do |k, v|
          LI() do
            A(href:"#", class: 'dropdown-item') do
              klass.human_attribute_name(k)
            end.on(:click) do |evt|
              evt.prevent_default
              assign_paths_for_attribute(k)
              mutate
              change!(@current_path, @previous_path)
              scroll_top_element_selected(::Element[evt.target.to_n])
            end
          end
        end
        associations.each do |association|
          next unless association.klass
          LI(class: ' dropdown-submenu dropright dropdown parent') do
            A(href:"#", class: 'dropdown-item dropdown-toggle') do
              klass.human_attribute_name(association.name)
            end
            DIV(class: "wrapper") do
            UL(class: 'dropdown-menu') do
              if @create_sub_menu == association.name
                if path.blank?    # New column
                  next_path = [association.name]
                  next_path.unshift(0) if !association_path.last.is_a?(Integer)
                  new_association_path = association_path + next_path
                else
                  path = []
                  association_path[-1] = association.name
                  new_association_path = association_path
                end
                  Crm::Import::RenderDropdownMenu(klass: association.klass, association: association, path: path, association_path: new_association_path).on(:change) do |current_path, previous_path|
                    change!(current_path, previous_path)
                  end
                end
              end
            end
          end.on(:click) do |evt|
            UL(class: 'dropdown-menu') do
              mutate @create_sub_menu = association.name
            end
          end
        end
      end

      def attributes
        attribute_names = klass.attribute_names.select{|a| !(a != 'old_crm_id' && a =~ /_id(s)?$/) }
        attribute_names << 'type' if klass.subclasses.any?
        return attribute_names.sort_by{|attr| klass.human_attribute_name(attr)}
      end

      def associations
        klass.reflect_on_all_associations.sort_by{|asso| klass.human_attribute_name(asso.name)}
      end

      def assign_paths_for_attribute(attribute)
        @previous_path = @current_path || path
        if association.nil?
          num = path.present? ? path[0] : 0
          @current_path = [num, attribute]
        elsif @previous_path.present?
          association_path[-1] = attribute
          @current_path = association_path
        elsif association_path.last.is_a?(Integer)
          @current_path = association_path + [attribute]
        else
          @current_path = association_path + [0, attribute]
        end
      end

      def scroll_top_element_selected(element)
        toolbar_height = ::Element.find('body').find('.toolbar').first.outerHeight() || 0
        element_dropdown_td = element.closest('td').length > 0 ? element.closest('td').offset().top : element.closest('div').offset().top;
        step_progress_height = ::Element.find('.step-progress-mapping').outerHeight().to_i
        top_position = element_dropdown_td - (step_progress_height + toolbar_height.to_i)
        `window.scrollTo({top: #{top_position}, behavior: 'smooth'})`
      end

    end
  end
end
