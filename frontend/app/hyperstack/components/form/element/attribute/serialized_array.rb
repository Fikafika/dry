# backtick_javascript: true
require 'components/form/element/attribute/base'

class Form
  module Element
    module Attribute
      class SerializedArray < ::Form::Element::Attribute::Base

        param :possible_values_timestamp, default: nil

        render { content }

        def default_editor
          'tree_select'
        end

        def possible_values
          return other_params[:possible_values] if other_params[:possible_values].is_a?(Proc)
          unless other_params[:accept_empty_value]
            return other_params[:possible_values] || []
          end
          [{label: I18n.t('shared.none'), value: ""}] + other_params[:possible_values] || []
        end

        def tree_select_default_value
          form&.submission&.read(path)
        end

        def render_input_tree_select
          layout_input do
            if possible_values.is_a?(Proc)
              TreeSelectWithComputedOptions(
                options: possible_values,
                options_timestamp: possible_values_timestamp,
                default_value: tree_select_default_value,
                selectable_expandable_option: other_params.has_key?(:selectable_expandable_option) ? other_params[:selectable_expandable_option] : true,
                is_invalid: self.record_is_invalid?,
                record_klass: other_params[:record_klass],
                disabled: disabled,
              ) do
                input_errors
              end.on(:change) do |event|
                change_value(event[:value])
              end
            else
              TreeSelect(
                options: possible_values,
                options_timestamp: possible_values_timestamp,
                default_value: tree_select_default_value,
                selectable_expandable_option: other_params.has_key?(:selectable_expandable_option) ? other_params[:selectable_expandable_option] : true,
                is_invalid: self.record_is_invalid?,
                disabled: disabled,
              ) do
                input_errors
              end.on(:change) do |event|
                change_value(event[:value])
              end
            end
          end
        end

        class TreeSelect < HyperComponent
          param :default_value, default: ""
          param :selectable_expandable_option, default: true
          param :options, default: []
          param :is_invalid, default: false
          param :options_timestamp, default: nil
          param :disabled, default: false

          fires :change

          before_mount do
            init_value
          end

          def init_value
            #search path in options from value
            init_body_listeners
            @value = default_value || ""
            @old_value = @value
            @old_options = options
            compute_value
          end

          after_update do
            update_value
          end

          def update_value
            if @old_options != options
              compute_value
              @old_options = options
              mutate
            end
            change_value(@value) unless @old_value == @value
            @old_value = @value
          end

          render { content(options) }

          def content(attr_options)
            DIV(class: "dropdown") do
              BUTTON(class: "form-control d-flex pr-1 text-left #{is_invalid ? 'is-invalid' : ''}", tabIndex: 0, disabled: disabled.to_n) do
                SPAN(class: "flex-grow-1", style: {cursor: 'default'}) do
                  @displayed_value.each_with_index do |dv, i|
                    I(class: "fa fa-chevron-right fa-xs mx-1") unless i == 0
                    SPAN do
                      dv
                    end
                  end
                end
                SPAN(class: "flex-grow-0") do
                  I(class: "fa #{is_invalid ? '' : 'fa-chevron-down'} fa-2xs mx-1", style:{WebkitTextStroke: "#{0.5}px"})
                end
              end.on(:click) do |event|
                self.jq_node.find('.dropdown-menu').toggle_class('show') unless disabled
              end
              children.render
              DIV(class: "border rounded-0 shadow dropdown-menu container p-0", style: {maxHeight: '50vh', overflow: 'auto'}) do
                attr_options.map do |option|
                  self.option(**option)
                end
              end
            end
          end

          def option(label: "", value: nil, options: nil, tree_level: 0)
            if options
              self.expandable_option(label, value, options, tree_level);
            else
              DIV(key:"#{label}#{tree_level}", class:"dropdown-item#{value == @value ? ' active': ''} px-1", style: { marginLeft: "#{tree_level}rem", width: "calc(100% - #{tree_level}rem)", minHeight: "2rem", cursor: 'pointer' }, value: value) do
                I(class: "fa fa-fw")
                label
              end.on(:click) do |event|
                set_value(value)
              end
            end
          end

          def expandable_option(label, value, options, tree_level = 0)
            DIV(class: "") do
              render_label(label, tree_level).on(:click) do |event|
                if !selectable_expandable_option || ::Element[event.target.to_n].has_class?('fa')
                  toggle_path("#{label}#{tree_level}", tree_level)
                else
                  set_value(value)
                end
              end
              DIV(class: "") do
                options.map do |option|
                  self.option(**option.merge(tree_level: tree_level + 1))
                end
              end if @path&.include?("#{label}#{tree_level}")
            end
          end

          def render_label(label, tree_level)
            DIV(class: "dropdown-item px-1" ,style: { marginLeft: "#{tree_level}rem", width: "calc(100% - #{tree_level}rem)", cursor: 'pointer' }) do
              I(class: "fa fa-chevron-#{@path&.include?("#{label}#{tree_level}")? 'down' : 'right'} fa-xs mr-1 fa-fw h-100")
              SPAN do
                label
              end
            end
          end

          def toggle_path(node, position)
            new_path = position != 0 ? @path[0..position-1] : []
            unless @path&.include?(node)
              new_path << node
            end
            @path = new_path
            mutate
          end

          def compute_value
            @path = path_from_value
            @displayed_value = displayed_value(@value) || []
          end

          def displayed_value(value, options = self.options)
            option = options.detect{|o| o.has_key?(:value) && o[:value] == value }
            return [option[:label]] if option
            options.each do |o|
              next unless o[:options]
              dv = displayed_value(value, o[:options])
              return dv.unshift(o[:label]) if dv
            end
            return nil
          end

          def path_from_value(options = self.options, group = nil, tree_level = 0)
            tree_node = group ? ["#{group}#{tree_level - 1}"] : []
            if options.any?{|o| o[:value] == @value }
              return tree_node
            else
              options.each do |o|
                next unless o[:options]
                o_path = path_from_value(o[:options], o[:label], tree_level + 1)
                return tree_node + o_path unless o_path.blank?
              end
            end
            return nil
          end

          def change_value(value)
            change!(value: value)
          end

          def set_value(new_value)
            @value = new_value
            @displayed_value = displayed_value(new_value) || []
            self.jq_node.find('.dropdown-menu').remove_class('show')
            mutate
          end

          def init_body_listeners
            ::Element['body'].on(:click) do |event|
              next unless @__hyperstack_component_is_mounted && self.jq_node.find('.dropdown-menu').hasClass('show')
              self.jq_node.find('.dropdown-menu').remove_class('show') unless event.target.closest('.dropdown').length > 0
            end

            ::Element[`window`].on(:blur) do |event|
              next unless @__hyperstack_component_is_mounted && self.jq_node.find('.dropdown-menu').hasClass('show')
              self.jq_node.find('.dropdown-menu').remove_class('show')
            end
          end

        end

        class TreeSelectWithComputedOptions < TreeSelect
          param :record_klass
          param :default_value

          def init_value
            @all_options = []
            @current_option_selected = {}
            init_all_options
            @old_default_value = default_value
            @old_options_timestamp = options_timestamp
            super
            @displayed_value = compute_label_from_value(default_value) if default_value
          end

          after_new_params do
            if @old_default_value != default_value || @old_options_timestamp != options_timestamp
              init_value
            end
          end

          def update_value
            change_value(@value) unless @old_value == @value
            @old_value = @value
          end

          render { content(@all_options) }

          def init_all_options
            @all_options = options.call(record_klass, '')
          end

          def option(label: "", value: nil, options: nil, klass: nil, tree_level: 0)
            if klass
              self.expandable_option(label, value, options, tree_level);
            else
              DIV(key:"#{label}#{tree_level}", class:"dropdown-item#{value == @value ? ' active': ''} px-1", style: { marginLeft: "#{tree_level}rem", width: "calc(100% - #{tree_level}rem)", minHeight: "2rem", cursor: 'pointer' }, value: value) do
                I(class: "fa fa-fw")
                label
              end.on(:click) do |event|
                set_value(value)
              end
            end
          end

          def expandable_option(label, value, options, tree_level = 0)
            DIV(class: "") do
              render_label(label, tree_level).on(:click) do |event|
                if !selectable_expandable_option || ::Element[event.target.to_n].has_class?('fa')
                  @current_option_selected = compute_current_selected_option(value)
                  if @current_option_selected
                    @current_option_selected[:options] = compute_options
                    toggle_path("#{label}#{tree_level}", tree_level)
                  end
                else
                  set_value(value)
                end
              end
              DIV(class: "") do
                options.map do |option|
                  self.option(**option)
                end if options.present?
              end if @path&.include?("#{label}#{tree_level}")
            end
          end

          def compute_current_selected_option(path_value)
            result = @all_options
            arr_path_value = path_value.split('.')
            current_string_path = ''
            arr_path_value.each_with_index do |p_value, i|
              result = result[:options] if i > 0
              current_string_path += "#{p_value}."
              result = result.detect{|a| a[:value] == current_string_path }
            end
            return result
          end

          def compute_options
            return unless @current_option_selected.present?
            return options.call(@current_option_selected[:klass], @current_option_selected[:value])
          end

          def compute_label_from_value(value)
            result = []
            r = @all_options
            value.split('.').each do |v|
              r = r.detect{|o| o[:value] == "#{v}." || o[:value] == v}
              next unless r
              result << r[:label]
              next unless r[:klass]
              r[:options] = options.call(r[:klass], '') unless r[:options]
              r = r[:options] if r[:options]
            end
            return result
          end

          def compute_value
            @path = path_from_value
            @displayed_value = displayed_value(@value) || []
          end

          def displayed_value(value, options = self.options)
            options = @all_options if options.is_a?(Proc)
            option = options.detect{|o| o.has_key?(:value) && o[:value] == value }
            return [option[:label]] if option
            options.each do |o|
              next unless o[:options]
              dv = displayed_value(value, o[:options])
              return dv.unshift(o[:label]) if dv
            end
            return nil
          end

          def path_from_value(options = self.options, group = nil, tree_level = 0)
            options = @all_options if options.is_a?(Proc)
            tree_node = group ? ["#{group}#{tree_level - 1}"] : []
            if options.any?{|o| o[:value] == @value }
              return tree_node
            else
              options.each do |o|
                next unless o[:options]
                opt = o[:options] || options
                o_path = path_from_value(opt, o[:label], tree_level + 1)
                return tree_node + o_path unless o_path.blank?
              end
            end
            return nil
          end

        end
      end
    end
  end
end
