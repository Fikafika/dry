# backtick_javascript: true

class Crm
  class MenuEditor < HyperComponent
    include Hyperstack::Router::Helpers
    include Router::Resources

    fires :close

    param :menu, default: nil
    param :item_id, default: nil

    render { content }

    def content
      if menu
        DIV(class: 'menu-editor h-100 w-100') do
          Tree(menu: menu, current_item: current_item, count: current_item&.updated_at).on(:item_changed) do |item|
            @current_item = item
            mutate
          end
          new_item_button
          ItemEditor(item: current_item).on(:item_changed) do |item, was_new_record|
            @current_item = item
            if was_new_record
              menu.items.push(item)
            end
            mutate
          end.on(:close) do
            close!
          end
        end
      else
        DIV{}
      end
    end

    def new_item_button
      DIV(class: 'add-button-panel') do
        BUTTON(class:"btn rounded-0 border-0 m-0 w-100 btn-primary") do
          SPAN(class: "fa fa-plus pr-2")
          I18n.t('shared.add')
        end.on(:click) do |event|
          item_klass = "#{menu.class.name}::Item".constantize # D::Uneek::R::Menu::Item
          @current_item = item_klass.new(menu_id: menu.id, menu: menu, position: 999999);
          mutate
        end
      end
    end

    def current_item
      return @current_item if @current_item
      if item_id
        @current_item = menu.items.detect{|i| i.id == item_id}
      end
    end

    class Tree < HyperComponent

      render do
        DIV(class: 'tree-panel border-right bg-white overflow-auto') do
          left_panel if menu
        end
      end

      param :menu, default: nil
      param :current_item, default: nil

      fires :item_changed

      collect_other_params_as :other_params

      def left_panel
        DIV() do
          menu.roots.each do |item|
            menu_item(item)
          end
        end
      end

      def menu_item(item)
        margin_padding = 'm-1'
        if item.parent_id.present?
          margin_padding = 'mt-1 mb-1 ml-3'
        end

        DIV(class: margin_padding) do
          active = ''
          if current_item && item.id == current_item.id
            active = 'active'
          end

          DIV(class: "d-flex list-group-item #{active} p-1 border rounded cursor-pointer #{item.permitted || item.new_record? ? '' : 'text-muted'}", "data-element_id": item.id, draggable: true) do
            item_icon = 'table'
            item_icon_size = '2x'
            if item.icon.present?
              item_icon = item.icon
            end

            if item.icon_size.present?
              item_icon_size = item.icon_size
            end

            DIV(class: "d-flex") do
              DIV(class: "fa fa-#{item_icon} fa-#{item_icon_size} fa-fw")
              DIV(class: "d-flex") do
                SPAN(class: "d-flex align-items-center pl-2") do
                  item.label
                end
              end
            end
            DIV(class: 'flex-grow-1') do
            end
            DIV(class: "d-flex") do
              BUTTON(class: "btn btn-transparent-light-yiq fa fa-trash", type: "button").on(:click) do |event|
                event.prevent_default
                item_id = ::Element.find(event.target.to_n).closest('.list-group-item').data('element_id')
                item_count = item.descendants.length + 1
                Modal.confirm(title: I18n.t('shared.delete'), text: I18n.t('crm.menu_editor.delete_message', count: item_count)) do
                  delete_item(item_id)
                end
              end
            end
          end.on(:click) do
            item_changed!(item)
          end.on(:dragStart) do |ev|
            item_id = ::Element.find(ev.target.to_n).closest('.list-group-item').attr('data-element_id')
            @dragged_item = menu.item_by_id(item_id)
          end.on(:dragEnd) do |ev|
            remove_element_border

            if @dragging_over_item_id && valid_drop?(@dragged_item.id, @dragging_over_item_id, @closest_position)
              hovered = menu.item_by_id(@dragging_over_item_id)
              update_positions(@dragged_item, hovered, @closest_position)
              mutate
              menu.save_items_position.then do
                mutate
              end
            end

            @dragged_item = nil
            @closest_position = nil
            @dragging_over_item_id = nil
          end.on(:dragOver) do |ev|
            drag_over(ev)
          end

          if item&.sub_menu&.length > 0
            item.sub_menu.each do |sub_m|
              menu_item(sub_m)
            end
          end
        end
      end

      def update_positions(dragged_item, hovered, position)
        if position == 'right'
          dragged_item.position = hovered.sub_menu.length
          dragged_item.parent_id = hovered.id
        else
          dragged_item.parent_id = hovered.parent_id
          dragged_item.position = (hovered.position || 0) + (position == 'top' ? -0.5 : 0.5)
          parent_chidren = hovered.parent&.sub_menu || menu.roots
          parent_chidren.each_with_index{|item, i | item.position = i } # recompute positions
        end
      end

      def delete_item(item_id)
        item_to_delete = menu.item_by_id(item_id)
        item_to_delete.destroy.then do |response|
          if response[:success]
            menu.items.delete(item_to_delete)
            item_changed!
            mutate
          end
        end
      end

      def drag_over(event)
        hovered_element = ::Element.find(event.target.to_n).closest('.list-group-item')
        dragging_over_item_id = hovered_element.attr('data-element_id')

        if @dragged_item && dragging_over_item_id && valid_drop?(@dragged_item.id, dragging_over_item_id, 'bottom')
          @dragging_over_item_id = dragging_over_item_id

          rect = Native(`#{hovered_element}[0].getBoundingClientRect()`)

          rect_arr_top_bottom = [{position: 'top', value: rect.top}, {position: 'bottom', value: rect.bottom}];
          closest_top_or_bottom = rect_arr_top_bottom.reduce do |prev, curr|
            if (curr[:value] - event.client_y).abs < (prev[:value] - event.client_y).abs
              {position: curr[:position], value: (curr[:value] - event.client_y).abs}
            else
              {position: prev[:position], value: (prev[:value] - event.client_y).abs}
            end
          end

          if valid_drop?(@dragged_item.id, dragging_over_item_id, 'right')
            rect_arr_right_left = [{position: 'right', value: rect.right}, {position: 'left', value: rect.left}];
            closest_right_or_left = rect_arr_right_left.reduce do |prev, curr|
              if (curr[:value] - event.client_x).abs < (prev[:value] - event.client_x).abs
                {position: curr[:position], value: (curr[:value] - event.client_x).abs}
              else
                {position: prev[:position], value: (prev[:value] - event.client_x).abs}
              end
            end
            closest_position = [closest_top_or_bottom, closest_right_or_left].reduce do |prev, curr|
              if curr[:value] < prev[:value]
                {position: curr[:position], value: curr[:value] - event.client_x}
              else
                {position: prev[:position], value: prev[:value]}
              end
            end
          else
            closest_position = closest_top_or_bottom
          end

          @closest_position = closest_position[:position]

          if dragging_over_item_id != @dragging_over_item_id
            # dragging over another item..
            remove_element_border if @dragging_over_item_id
            add_element_border(hovered_element, closest_position[:position])
          else
            # dragging on the same item
            if (closest_position[:position] != @closest_position) || (@closest_position != nil)
              # position changed
              remove_element_border
              add_element_border(hovered_element, closest_position[:position])
            end
          end

        else
          @dragging_over_item_id = nil
        end

      end

      def valid_drop?(dragged_id, hovered_id, position)
        return false if dragged_id == hovered_id

        h = menu.item_by_id(hovered_id)

        max_depth = 1
        d = 0
        loop do
          if h.parent_id == dragged_id
            return false
          else
            h = h.parent
          end
          return false if position == 'right' && d == max_depth
          d += 1

          break unless h
        end

        return true
      end

      def add_element_border(element, position)
        element.parent.add_class('menu-editor-border').add_class(position)
      end

      def remove_element_border
        ::Element.find('.menu-editor-border')
          .remove_class('menu-editor-border')
          .remove_class('top')
          .remove_class('bottom')
          .remove_class('right')
          .remove_class('left')
      end

    end

    class ItemEditor < HyperComponent
      include UrlHelper
      include ::PermittedKlass

      render() do
        DIV(class: 'item-editor') do
          content_panel
        end
      end

      param :item, default: nil

      fires :item_changed
      fires :close

      def content_panel
        close_btn
        DIV() do
          if item && all_layouts.loaded?
            was_new_record = item.new_record?
            Form(
              record: item,
              class: 'container-fluid'
            ) do
              unless item.permitted || item.new_record?
                DIV(class: "alert alert-warning") do
                  I18n.t('crm.menu_editor.unauthorized')
                end
              end
              Form::Element::Attribute::TranslatableString(
                attribute_name: 'label',
                auto_focus: true,
              )
              Form::Element::Attribute::Icon(
                attribute_name: 'icon',
                placeholder_icon: 'table'
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'klass_name',
                possible_values: klass_names
              ).on(:change) do |value, form|
                change_defaults('klass_name', value, form)
                change_link(form)
                mutate
              end
              Form::Element::Attribute::Enum(
                attribute_name: 'layout',
                possible_values: Proc.new {|form| layouts(form) },
              ).on(:change) do |value, form|
                change_parameter(form, 'l', value)
                change_link(form)
                mutate
              end
              Form::Element::Attribute::Enum(
                attribute_name: 'action',
              ).on(:change) do |value, form|
                change_link(form)
                mutate
              end
              Form::Element::Attribute::String(
                attribute_name: 'parameters',
              ).on(:change) do |value, form|
                change_link(form)
                mutate
              end
              Form::Element::Attribute::String(
                attribute_name: 'link',
              ).on(:change) do |value, form|
                value = remove_current_domain_from_url(value)
                value = remove_param_from_url(value, 'mi')
                form.submission.write_from_user(['base', 'action'], item.class.extract_action_from_link(value))
                form.submission.write_from_user(['base', 'parameters'], item.class.extract_parameters_from_link(value))
                form.submission.write_from_user(['base', 'klass_name'], item.class.extract_klass_name_from_link(value))
                form.submission.write_from_user(['base', 'link'], value)
                mutate
              end
              Form::Element::Attribute::String(
                attribute_name: 'menu_id',
                editor: 'hidden'
              )
              Form::Element::Attribute::String(
                attribute_name: 'position',
                editor: 'hidden'
              )
              Form::Footer()
            end.on(:success) do
              was_new_record = item.status_code == 201
              item_changed!(item, was_new_record)
              mutate
              App.history.push(add_param_to_url(item.link, 'mi', item.id))
            end
          end

        end
      end

      def close_btn
        DIV(class: 'clearfix px-2 mb-2') do
          IconButton(text: I18n.t('shared.back'), icon: "chevron-left", variant: 'transparent-light-yiq', class: 'float-right').on(:click) do |event|
            event.prevent_default
            event.stop_propagation
            close!
          end
        end
      end

      def change_defaults(attribute_name, value, form)
        change_parameter(form, 'l', nil)
        form.submission.write_from_user(['base', 'layout'], nil)
        form.submission.write_from_user(['base', 'action'], 'last_search')
      end

      def change_parameter(form, param, value)
        parameters = form.submission.read(['base', 'parameters']).to_s.split('&')
        if value.present?
          p = parameters.detect{|p| p.start_with?("#{param}=")}
          v = "#{param}=#{value}"
          if p
            p_ = p.gsub(/#{param}=.*/, v)
            parameters[parameters.index(p)] = p_
          else
            parameters << v
          end
        else
          parameters.delete_if{|p| p.start_with?("#{param}=")}
        end
        form.submission.write_from_user(['base', 'parameters'], parameters.join('&'))
      end

      def change_link(form)
        schema = schema_name
        klass = form.submission.read(['base', 'klass_name'])
        return unless schema.present? && klass.present?
        action = form.submission.read(['base', 'action'])
        link = interpolate_path("/crm/:schema/table/:klass#{'/:action' if action.present?}", { schema: schema, klass: klass, action: action })
        parameters = form.submission.read(['base', 'parameters'])
        link = "#{link}?#{parameters}" if parameters.present?
        form.submission.write_from_user(['base', 'link'], link)
      end

      def remove_current_domain_from_url(url)
        current_domain = "#{`window.location.protocol`}//#{`window.location.hostname`}"
        return url.sub(current_domain, '')
      end

      def klass_names
        permitted_klasses_for_action(schema.klasses.map(&:const_absolute_name), :R)&.map do |klass_name|
          k = schema.klasses.detect {|klass| klass.const_absolute_name == klass_name}
          { value: k.route_key, label: k.human_name }
        end || []
      end

      def schema
        return @schema if @schema && @schema.loaded?
        @schema = Dynamic::Schema.load(schema_name)
        return @schema
      end

      def layouts(form)
        return [] unless all_layouts.loaded? && schema&.constants_loaded?
        route_key = form.submission.read(['base', 'klass_name'])
        klass_name = schema.const.const_klasses_by_route_key[route_key]&.name
        result = []
        all_layouts.each do |l|
          next unless l.klass_name == klass_name
          result << { value: l.id, label: l.human_name }
        end
        return result
      end

      def all_layouts
        observe @all_layouts ||= Dynamic::Layout.with_action('index').where(schema_id: schema.name).all
      end

      def schema_name
        request.params[:schema] || request.params[:schema_id]
      end
    end
  end
end
