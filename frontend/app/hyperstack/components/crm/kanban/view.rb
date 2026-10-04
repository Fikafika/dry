require 'components/crm'

class Crm
  class Kanban
    class View < HyperComponent
      include Hyperstack::Router::Helpers
      include ::Router::Resources
      include ::Crm::Routes::Helpers

      param :current_sprint, default: nil
      param :sprint_dropdown, default: false
      param :sprint_param, default: nil
      param :relation, default: nil
      param :column_attribute, default: nil
      param :column_settings, default: nil
      param :column_states, default: nil
      param :reload, default: nil

      fires :drop_column
      fires :toggle_column

      before_mount do
        init_columns
        @dragging_column = false
        @dragging_ticket = false
      end

      def init_columns
        relation_changed = @old_relation != klass
        @related_tickets = nil
        @current_sprint = current_sprint
        @default_current_sprint = current_sprint
        @sprints = nil
        @columns = column_settings
        @ticket = nil
        if relation_changed
          @scrollers = {}
          @reload_keys = Hash.new(0)
          @count_reload_keys = Hash.new(0)
          @sprint_reload_key = 0
        end
        @column_name_dragged_id = nil
        @old_column_settings = column_settings
        @old_relation = klass
        @old_default_current_sprint = current_sprint
        init_column_states
      end

      def init_column_states
        if @old_column_states != column_states
          @column_states = column_states
          @old_column_states = column_states
        end
      end

      after_new_params do
        if init_columns?
          init_columns
        end
      end

      def init_columns?
        @old_column_settings != column_settings || @old_relation != relation || @old_default_current_sprint != current_sprint || @old_column_states != column_states
      end

      before_render do
        if @old_current_sprint != @current_sprint
          @sprint_reload_key += 1
          @old_current_sprint = @current_sprint
        end
      end

      render do
        if sorted_columns.any?
          @sprint_klass = klass.reflect_on_association(sprint_param)&.klass
          @sprints = all_sprints
          if sprint_dropdown
            DIV(class: 'container pt-2') do
              DIV(class: 'form-group') do
                SELECT(class: "form-control form-select", "aria-label": "Default select example") do
                  if @default_current_sprint
                    OPTION(value: 0) do
                      I18n.t('crm.kanban.select_sprint')
                    end
                  else
                    OPTION("selected", value: 0) do
                      I18n.t('crm.kanban.select_sprint')
                    end
                  end

                  sprint_index = 1
                  @sprints.each do |s|
                    if @default_current_sprint and @default_current_sprint.attributes["id"] == s.attributes["id"]
                      OPTION("selected", value: sprint_index) do
                        s.attributes["name"]
                      end
                    else
                      OPTION(value: sprint_index) do
                        s.attributes["name"]
                      end
                    end
                    sprint_index += 1
                  end
                end.on(:change) do |e|
                  if e.target.value == "0"
                    @current_sprint = nil
                  else
                    @current_sprint = @sprints[e.target.value.to_i - 1] if @sprints
                  end
                  mutate
                end
              end
            end
          end

          DIV(class: "kanban-main p-2") do
            sorted_columns.uniq.each_with_index do |col, index|
              col_id = compute_column_id(col[:column_id])
              col_state = @column_states.present? ? @column_states[col_id] == 'OPEN' : false
              DIV(key: "#{compute_label_from_column_id(col[:column_id])}_#{index}", "data-element_id": col["value"] || 'non-categorized-col', draggable: true, class: 'kanban-column-wrapper side-panel') do
                Crm::Kanban::Column(column_name: compute_label_from_column_id(col[:column_id]),
                  count_render: -> {
                    Crm::Kanban::Counter(
                      scope: build_scope(col[:value]),
                      reload: @count_reload_keys[col[:value]]
                    )
                  },
                  opened: col_state
                ) do
                  if col_state
                    InfiniteScroll(
                      DIV,
                      class: "panel-block bd-highlight",
                      style: { flexBasis: "100%", maxHeight: "80vh", overflowY: "auto" },
                      items: build_scroll_scope(col[:value]),
                      reload: [reload, @sprint_reload_key, @reload_keys[col[:value]]],
                      on_ready: ->(instance) { @scrollers[col[:value]] = instance },
                      per_page: tickets_page_size
                    ) do |t|
                      DIV(class: "bd-highlight cursor-pointer") do
                        DIV(class: "card", draggable: true, "data-id": t.id) do
                          DIV(class: 'border rounded p-3 text-left') do
                            ::Crm::List::Item(record: t, purpose: 'thumbnail')
                          end
                        end.on(:drag_start) do |ev|
                          @ticket = t
                          @move_permission = true
                          element = ::Element.find(ev.target.to_n).closest(".card")
                          element.add_class("dragging")
                          @dragging_ticket = true
                          name = klass.name.split('::')[2]
                          icon = drag_icon(name)
                          ev.native_event.dataTransfer.setDragImage(icon, 0, 0)
                          after(0.01) do
                            `icon.remove()`
                          end
                        end.on(:drag_over) do |ev|
                          ev.prevent_default
                          @move_permission = true
                          if (@ticket && t.id == @ticket.id) ||(@ticket && t.id == next_ticket_column(@ticket, col[:value]))
                            @move_permission = false
                            remove_placeholder
                          elsif @ticket && last_ticket_column(t.id, col[:value])
                            wrapper = ::Element.find(ev.target.to_n).closest('.kanban-column-wrapper')
                            move_placeholder_to_end(wrapper)
                            @drop_target_ticket_id = t.id
                          else
                            move_placeholder(t.id)
                          end
                        end.on(:drag_leave) do |ev|
                          ev.prevent_default
                          is_placeholder = ::Element.find(ev.target.to_n).closest(".ticket-placeholder")
                          next if is_placeholder
                          @move_permission = false
                        end.on(:drag_end) do |ev|
                          element = ::Element.find(ev.target.to_n).closest(".card")
                          element.remove_class("dragging")
                          @dragging_ticket = false
                          element.remove_attr("style")
                          remove_placeholder
                          @ticket = nil
                        end
                      end.on(:click) do
                        App.history.push(App.location.add_params(rp: edit_url(t.class, t.id)))
                      end
                    end
                  else
                    DIV(class: "panel-block bd-highlight", style: { flexBasis: "100%" })
                  end
                  DIV(class: "kanban-column-footer") do
                    DIV(class: "d-flex justify-content-center") do
                      pre_filled_attr_params = "?params[#{klass.name.demodulize.downcase}@0][#{column_attribute}]#{'[id]' if column_attribute_reflection}=#{col["value"]}"
                      Link("#{new_url(klass)}#{pre_filled_attr_params}", class: "btn btn-transparent-light-yiq d-flex w-100 justify-content-center pt-2", "data-open-panel": "right") do
                        SPAN(class: "fa fa-plus")
                        P(class: "mb-0"){ I18n.t('shared.new') }
                      end
                    end
                  end
                end.on(:toggle_column) do |opened_column|
                  col_id = compute_column_id(col[:column_id])
                  change_column_states(col_id, opened_column)
                  toggle_column!(@column_states)
                  mutate
                end
              end.on(:drag_start) do |ev|
                column_target = ::Element.find(ev.target.to_n)
                next unless column_target.has_class?("kanban-column-wrapper")
                wrapper = column_target.closest(".kanban-column-wrapper")
                wrapper.add_class("dragging-column")
                @dragging_column = true
                icon = drag_icon(compute_label_from_column_id(col[:column_id]))
                ev.native_event.dataTransfer.setDragImage(icon, -5, 16)
                after(0.01) do
                  `icon.remove()`
                end
                @column_name_dragged_id = column_target.closest('.kanban-column-wrapper').attr('data-element_id') if column_target.class_name.include? 'kanban-column-wrapper'
              end.on(:drag_over) do |ev|
                ev.prevent_default
                if @dragging_column
                  drag_over_column(ev)
                  remove_placeholder
                elsif @dragging_ticket
                  wrapper = ::Element.find(ev.current_target.to_n)
                  hovered = ::Element.find(ev.target.to_n)
                  number_cards = hovered.closest(".kanban-column").find(".card").length
                  in_column = hovered.closest(".kanban-column").length > 0

                  if number_cards == 0 && in_column
                    @drop_target_ticket_id = nil
                    move_placeholder_to_start(wrapper)
                  end

                  drag_over_ticket(ev)
                end
              end.on(:drag_leave) do |ev|
                wrapper = ::Element.find(ev.current_target.to_n)
                wrapper.remove_class("kanban-background-transparent-light-yiq")
                remove_placeholder if ::Element.find(ev.target.to_n).closest(".panel-block").length == 0
              end.on(:drag_end) do |ev|
                wrapper = ::Element.find(ev.target.to_n).closest(".kanban-column-wrapper")
                wrapper.remove_class("dragging-column")
                @dragging_column = false
                if @column_name_dragged_id && reorder_columns
                  drop_column!(@columns)
                  mutate
                end
                @column_name_dragged_id = nil
                @new_position = nil
              end.on(:drop) do |ev|
                drop_and_update_ticket(ev, col[:value]) if @ticket && @dragging_ticket
              end
            end
          end
        elsif klass.reflect_on_association(sprint_param)
          DIV do
            I18n.t('crm.kanban.error_attribute_not_in_klass', attribute: column_attribute, klass: klass.name.demodulize.downcase)
          end
        end
      end

      def compute_column_id(column_id)
        return column_id if column_id
        'non-categorized-col'
      end

      def reorder_columns
        dragged_id = @column_name_dragged_id == 'non-categorized-col' ? nil : @column_name_dragged_id
        columns = @columns.sort_by { |column| column[:position] }
        old_position = columns.index{ |column| column[:value] == dragged_id }
        return unless old_position
        return if old_position == @new_position
        dragged_column = columns.delete_at(old_position)
        columns.insert(@new_position, dragged_column)
        columns.each_with_index do |column, index|
          column[:position] = index
        end
      end

      def next_ticket_column(ticket, col_value)
        return unless ticket
        scroller = @scrollers[col_value]
        loaded = scroller ? scroller.loaded_records : []
        idx = loaded.index { |r| r.id == ticket.id }
        return nil unless idx
        next_ticket = loaded[idx + 1]
        next_ticket&.id
      end

      def last_ticket_column(target_ticket_id, col_value)
        return false unless target_ticket_id
        scroller = @scrollers[col_value]
        last_ticket = scroller ? scroller.loaded_records.last : nil
        return true if last_ticket.id == target_ticket_id
        return false
      end

      def drop_and_update_ticket(evt, value)
        remove_placeholder
        ::Element.find(evt.current_target.to_n).find(".kanban-column").remove_class("drop-target")
        div_target = ::Element.find(evt.current_target.to_n)
        col_target = value
        attr = column_attribute_reflection ? "#{column_attribute}_id" : column_attribute
        col_source = @ticket.send(attr)
        moved_ticket = @ticket
        target_ticket_id = @drop_target_ticket_id

        perform_ticket_move(moved_ticket, col_source, col_target, target_ticket_id)

        @drop_target_ticket_id = nil
        @ticket = nil
        div_target.remove_class 'kanban-background-transparent-light-yiq'
      end

      def perform_ticket_move(moved_ticket, col_source, col_target, target_ticket_id)
        attr = column_attribute_reflection ? "#{column_attribute}_id" : column_attribute
        changed_column = col_source != col_target
        source_needs_reload = false

        if changed_column
          update_column_after_move(col_source) do |scroller|
            scroller.remove_record(moved_ticket.id)
            source_needs_reload = !scroller.finished?
          end
        end

        if @move_permission
          direction = last_ticket_column(target_ticket_id, col_target) == true ? "after" : "before"
          relation.update_positions(
            source_id: moved_ticket.id,
            target_id: target_ticket_id,
            direction: direction,
            attr: attr,
            source: col_source,
            target: col_target,
          ).then do |response|
            update_ticket(moved_ticket, col_target, response, changed_column)

            update_column_after_move(col_target) do |scroller|
              if target_ticket_id
                scroller.insert_record_at(moved_ticket, target_ticket_id, direction)
              else
                scroller.prepend_record(moved_ticket)
              end
            end

            if changed_column
              @count_reload_keys[col_source] += 1
              @count_reload_keys[col_target] += 1
              @reload_keys[col_source] += 1 if source_needs_reload
            end
            mutate
          end
        end
      end

      def update_column_after_move(col_value)
        scroller = @scrollers[col_value]
        return unless scroller
        yield scroller
      end

      def update_ticket(ticket, col_target, response, changed_column)
        attr = column_attribute_reflection ? "#{column_attribute}_id" : column_attribute

        ticket.send("#{attr}=", col_target) if changed_column

        if ticket.scope[:where]
          ticket.scope[:where] = ticket.scope[:where].except(
            column_attribute.to_s,
            "#{column_attribute}_id"
          )
        end
      end

      def drag_over_column(event)
        hovered_element = ::Element.find(event.target.to_n).closest('.kanban-column-wrapper')
        dragging_over_item_id = hovered_element.attr('data-element_id')
        return unless dragging_over_item_id
        dragging_over_item_id = dragging_over_item_id == 'non-categorized-col' ? nil : dragging_over_item_id
        dragging_over_item = @columns.detect{|col| col[:value] == dragging_over_item_id}
        @new_position = dragging_over_item[:position]
      end

      def drag_over_ticket(evt)
        div_target = ::Element.find(evt.current_target.to_n)
        div_target.add_class('kanban-background-transparent-light-yiq') unless div_target.has_class?('kanban-background-transparent-light-yiq')
      end

      def klass
        if relation.is_a?(HyperResource::Relation)
          relation.klass
        else
          relation
        end
      end

      def build_scope(col_value)
        scope = relation.new_relation
        attr = column_attribute_reflection ? "#{column_attribute}_id" : column_attribute

        scope = scope.join_positions(attr)
        scope = scope.where(attr => col_value)

        if @current_sprint
          scope = scope.merge_where("#{sprint_param}_id" => @current_sprint.id)
        end

        scope = scope.order(value: :asc, id: :asc)

        return scope
      end

      def build_scroll_scope(col_value)
        build_scope(col_value).per(tickets_page_size)
      end

      def tickets_page_size
        10
      end

      def check_placeholder
        return @drop_placeholder if @drop_placeholder
        placeholder = `document.createElement("div")`
        `placeholder.className = "ticket-placeholder"`
        @drop_placeholder = placeholder
      end

      def move_placeholder(before_ticket_id)
        placeholder = check_placeholder
        if before_ticket_id
          @drop_target_ticket_id = before_ticket_id
          %x{
            (function(){
              var target = document.querySelector('.card[data-id="' + #{before_ticket_id.to_s} + '"]');
              if (target && target.parentNode) {
                target.parentNode.insertBefore(#{placeholder}, target);
              }
            })();
          }
        else
          %x{
            (function(){
              var container = document.querySelector(".kanban-column.drop-target .panel-block");
              if (container) {
                container.appendChild(#{placeholder});
              }
            })();
          }
        end
      end

      def move_placeholder_to_start(wrapper)
        placeholder = check_placeholder
        return unless placeholder

        container = wrapper.find(".panel-block")
        return if container.length == 0

        first_card = container.find(".card").first

        if first_card
          first_card.before(placeholder)
        else
          container.append(placeholder)
        end

        @move_permission = true
      end

      def move_placeholder_to_end(wrapper)
        placeholder = check_placeholder
        return unless placeholder

        container = wrapper.find(".panel-block")
        return if container.length == 0

        last_card = container.find(".card").last

        if last_card
          last_card.after(placeholder)
        else
          container.append(placeholder)
        end
      end

      def remove_placeholder
        if @drop_placeholder
          `#{@drop_placeholder}.remove()`
          @drop_placeholder = nil
        end
      end

      def column_attribute_reflection
        klass.reflect_on_association(column_attribute)
      end

      def all_sprints
        return [] unless @sprint_klass
        return @all_sprint if @all_sprint
        @all_sprint = @sprint_klass.all
        observe @all_sprint
      end

      def sorted_columns
        columns.sort_by{|col| col[:position]}
      end

      def change_column_states(column_id, opened_state)
        @column_states ||= {}
        @column_states[column_id] = opened_state ? 'OPEN' : 'CLOSED'# TODO change to boolean when Opal is upgraded
      end

      def is_default_column_settings
        @columns.size == 1 && @columns.first[:value].nil?
      end

      def compute_label_from_column_id(column_id)
        return I18n.t("crm.kanban.not_categorized") unless column_id
        if reflection = column_attribute_reflection
          k = reflection.klass
          if k && association_records.present?
            association_records.detect{|r| r.id == column_id}&.send(k.name_attribute)
          end
        else
          klass.attributes.dig(column_attribute, "mapping", I18n.locale).detect{|k, v| v == column_id}&.first
        end
      end

      def association_records
        return unless column_attribute_reflection
        return @association_records if @association_records
        @association_records = observe column_attribute_reflection.klass.limit(500).all
      end

      def columns
        return @columns if @columns && !is_default_column_settings
        result = [{ "value": nil, "column_id": nil, position: 0 }]
        if klass.attributes[column_attribute]
          klass.attributes.dig(column_attribute, 'possible_values', I18n.locale).each_with_index do |possible_value, index|
            column = {
              value: possible_value[:value],
              column_id: klass.attributes.dig(column_attribute, 'mapping', I18n.locale, possible_value[:label]),
              position: index + 1,
            }
            result << column
          end
          @columns = result
        elsif column_attribute_reflection
          if association_records.present?
            association_records.each_with_index do |association_record, index|
              result << { value: association_record.id, position: index + 1, column_id: association_record.id }
            end
            @columns = result
          end
        end
        return result
      end

      def drag_icon(title)
        icon = `document.createElement("div")`
        %x{
          var icon_i = document.createElement("i");
          var text = document.createElement("span");
          icon_i.className = "fa fa-file";
          text.textContent = #{title};
          icon.appendChild(icon_i);
          icon.appendChild(text);
          icon.style.display = "flex";
          icon.style.alignItems = "center";
          icon.style.gap = "8px";
          icon.style.background = "#d8d8d8";
          icon.style.padding = "8px 12px";
          icon.style.borderRadius = "8px";
          icon.style.position = "absolute";
          document.body.appendChild(icon);
        }
        icon
      end

      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Kanban::View'

        def apply(params, options = {})
          return {
            relation: options.dig(:layout_params, :relation) || options.dig(:layout_params, :klass),
            column_states: options.dig(:layout_params, :column_states),
            on_drop_column: options.dig(:layout_params, :drop_column),
            on_toggle_column: options.dig(:layout_params, :toggle_column)
          }
        end
      end
    end
  end

end
