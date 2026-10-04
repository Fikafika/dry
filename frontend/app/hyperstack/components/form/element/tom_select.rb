# backtick_javascript: true

require 'components/form'
require 'active_support/concern'

class Form
  module Element
    module TomSelect
      extend ActiveSupport::Concern

      included do

        after_mount do
          init_tom_select_events if use_tom_select?
        end

        after_update do
          update_tom_select_events if use_tom_select?
        end

        before_unmount do
          finish_tom_select_events if use_tom_select?
        end

      end

      def update_tom_select_events
        finish_tom_select_events if must_destroy_tom_select?
        init_tom_select_events if !tom_select_initialized?
        update_tom_select_values if must_update_tom_select_values?
        copy_invalid_class_to_tom_select if record_is_invalid_changed?
        update_disabled_to_tom_select if tom_select_disabled_changed?
      end

      def init_tom_select_events
        return if @doing_init_tom_select_events
        @doing_init_tom_select_events = true
        @previous_record_id = record&.id

        @ajax = nil
        # puts "options init top select  : #{tom_select_options.inspect}"
        @tom_select = `new TomSelect(#{select_node}, #{tom_select_options.to_n})`
        `#{@tom_select}.hyperstack_component = #{self}`
        select_element.on(:change) do |event|
          @changed_by_user = true
          change_value(value_from_tom_select_data)
        end

        @tom_select_initialized = true
        @doing_init_tom_select_events = false
      end

      def value_from_tom_select_data
        `#{@tom_select}.items`.dup
      end

      def render_input_tom_select
        render_input_select2
      end

      def use_tom_select?
        ['select2', 'tom_select'].include?(editor || try(:default_editor)) && [nil, 'input'].include?(mode)
      end

      def finish_tom_select_events
        return unless tom_select_initialized?
        %x{
          #{@tom_select}.destroy()
          #{@tom_select}.tomselect = undefined;
        }
        @previous_record_id = nil
        @tom_select_initialized = false
      end

      def select_element
        self.jq_node.find('select')
      end

      def select_node
        `#{select_element.to_n}[0]`
      end

      def tom_select_initialized?
        @tom_select_initialized
      end

      def tom_select_options
        raise 'not implemented'
      end

      def copy_invalid_class_to_tom_select
        #copy invalid css class to wrapper
        invalid_css_class.blank? ? `$(#{input_css_id}).next(".ts-wrapper").removeClass("is-invalid")` : `$(#{input_css_id}).next().addClass("is-invalid")`
      end

      def update_tom_select_values
        s = selected_values
        return unless s

        # change options in order to set value
        `#{@tom_select}.setupOptions(#{s.map{|e| {id: e[:value], text: e[:label]}}.to_n})` if s.any?

        # update labels that are missing
        s.each do |e|
          next unless e[:label].present?
          o = `#{@tom_select}.options[#{e[:value]}]`
          next unless o
          `#{o}.text = #{e[:label]}`
        end

        # set value
        `#{@tom_select}.setValue(#{s.map{|e| e[:value]}.to_n}, true)`

        # restore options
        if respond_to?(:possible_values) && possible_values.any?
          `#{@tom_select}.setupOptions(#{possible_values.map{|e| {id: e[:value], text: e[:label]}}.to_n})`
        else
          `#{@tom_select}.clearOptions()`
        end
      end

      def must_update_tom_select_values?
        return false unless tom_select_initialized? && form

        result = false
        if @previous_submission && @previous_submission != form.submission
          result = true
        end
        @previous_submission = form.submission

        if !@changed_by_user && (@previous_value || form.submission.read(path)) && @previous_value != form.submission.read(path)
          result = true
        end
        @changed_by_user = false
        @previous_value = form.submission.read(path) if form

        return result
      end

      def must_destroy_tom_select?
        return false unless @previous_record_id
        return @previous_record_id != record&.id
      end

      def tom_select_disabled_changed?
        return false # must be redefined
      end

      def update_disabled_to_tom_select
        # must be redefined
      end

    end
  end
end
