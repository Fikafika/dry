require 'components/form/element/layout/base'

class Form
  module Element
    module Layout
      class Condition < ::Form::Element::Layout::Base
        collect_other_params_as :other_params

        render { content }

        def content
          if in_editor
            content_in_editor
          else
            form.condition_elements << self if form
            if rendering_condition_fulfilled?
              @previously_fullfiled = true
              children_render
            elsif @previously_fullfiled
              @previously_fullfiled = false
              clean
            end
          end
        end

        before_unmount do
          # clean ?
          form&.condition_attrs_to_clean&.delete(self)
        end

        def content_in_editor
          DIV(ref: _ref, class: "row mb-1") do
            DIV(class: 'col') do
              DIV(class: 'row') do
                DIV(class: "col") do
                  label.blank? ? 'Condition' : label
                end
              end
              DIV(class: "row") do
                DIV(class: 'col') do
                  children.render
                end
              end
            end
            if children.length == 0
              DIV(class: 'form-editor-dropzone') do
              end
            end
          end
        end

        def rendering_condition_fulfilled?
          return condition_formula_fulfilled? if with_condition_formula?
          return condition_fulfilled?
        end

        private

        def condition_formula_fulfilled?
          Dynamic::Form::Element::Layout::Condition::Evaluator.new(condition_formula).run_eval( Proc.new { |path| get_attributes_value(path) } )
        end

        def get_attributes_value(path)
          path = build_path(path.split('.'))

          if form.submission.has_association?(path)
            return form.submission.read_association(path)
          elsif form.submission.has_key?(path)
            return form.submission.read(path)
          else
            result = []
            available_locales_attributes_for(path.last).each do |attr|
              path[-1] = attr
              result << form.submission.read(path) if form.submission.has_key?(path)
            end
            return result
          end
        end

        def build_path(var_path)
          path = [prefix_path.first]
          var_path.each do |attr|
            path << 0
            path << attr.delete('[]')
          end
          return path
        end

        def available_locales_attributes_for(attr)
          return I18n.available_locales.map { |locale| "#{attr}_#{locale}" }
        end

        def condition_fulfilled?
          if other_params[:proc]
            return other_params[:proc].call(record, form)
          elsif record && form
            return false unless record_attr

            case other_params[record_attr]
            when Hash
              op = other_params[record_attr].keys.first
              value = other_params[record_attr][op]
            when Array
              value = other_params[record_attr]
              op = :in
            else
              value = other_params[record_attr]
              op = :eq
            end

            value = '1' if value == true
            value = '0' if value == false

            case op
            when :eq
              return (record_attr_value || '0') == value
            when :neq
              return (record_attr_value || '0') != value
            when :in
              return value.include?(record_attr_value)
            when :like
              return record_attr_value =~ value
            end
          else
            return false
          end
        end

        def record_attr
          other_params.keys.first
        end

        def record_attr_value
          path = prefix_path + [record_attr]
          if form.submission.has_key?(path)
            return form.submission.read(path)
          else
            return record.send(record_attr)
          end
        end

        def with_condition_formula?
          !!condition_formula
        end

        def to_clean
          return other_params[:to_clean] if other_params[:to_clean]
          return form.condition_attrs_to_clean.dig(self)&.keys || []
        end

        def clean
          to_clean.each do |p|
            p_ = p.is_a?(String) ? prefix_path + Array(p) : p
            form.submission.delete(p_)
          end
        end

        def children_render
          if !in_editor && self.form
            children_conditions = conditions + [self]
            children.each  do |c|
              self.form&.render_child(c, prefix_path, record, children_conditions, in_hash)
            end
          else
            children.render
          end
        end
      end
    end
  end
end
