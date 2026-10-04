require 'components/form/editor/panel/association/filters'

class Settings
  class Schema
    class Associations
      class DefaultFilters < ::Form::Editor::Panel::Association::Filters

        param :get_variable, default: nil

        def render_input
          observe klass.options_for_indexed_json
          layout_input do
            next unless klass.options_for_indexed_json.loaded?
            value = form.submission.read(path) || {}
            if @list.blank? || value != @old_value
              @list = ::Crm::Filters::AdvancedList.convert_from_hash(value, klass, name_without_brackets: true, normalize: true)
              @old_value = value
            end
            ::Crm::Filters::AdvancedList(list: @list, klass: klass, root_klass: root_klass, get_variable: get_variable, variable_possible_values: variable_possible_values).on(:change) do |list|
              @list = list
              hash = ::Crm::Filters::AdvancedList.convert_to_hash(list, name_without_brackets: true, simplify: true)
              change_value(hash)
              @old_value = hash
              mutate
            end
          end
        end

        def variable_possible_values
          return if get_variable
          return unless root_klass
          @variable_possible_values ||= begin
            result = []
            root_klass.attribute_names.each do |attr|
              next if attr == 'id' || attr.end_with?('_id') || attr.end_with?('_ids')
              result << {label: root_klass.human_attribute_name(attr), value: attr}
            end
            root_klass.reflect_on_all_associations.each do |reflection|
              result << {label: root_klass.human_attribute_name(reflection.name), value: reflection.name}
            end
            result.sort_by{|o| o[:label].to_s }
          end
        end

        def layout_input
          DIV(class: 'row form-group') do
            LABEL(class: "col-md-3 col-form-label control-label") do
              I18n.t('activerecord.attributes.dynamic/schema/association/base.default_elasticsearch_filters')
            end
            DIV(class: "col-md-9") do
              yield
            end
          end
        end

      end
    end
  end
end
