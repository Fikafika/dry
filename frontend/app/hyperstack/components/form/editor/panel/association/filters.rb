require 'components/form/element/base'
class Form
  class Editor
    module Panel
      module Association
        class Filters < ::Form::Element::Base

          param :klass
          param :root_klass
          param :get_variable

          def render_input
            observe klass.options_for_indexed_json
            layout_input do
              if klass.options_for_indexed_json.loaded?
                value = form.submission.read(path)
                if @list.blank? || value != @old_value
                  @list = ::Crm::Filters::AdvancedList.convert_from_hash(value, klass, name_without_brackets: true, normalize: true)
                  @old_value = value
                end
                ::Crm::Filters::AdvancedList(
                  list: @list, klass: klass,
                  root_klass: root_klass,
                  get_variable: get_variable,
                  enable_default_filters: false,
                ).on(:change) do |list|
                  @list = list
                  hash = ::Crm::Filters::AdvancedList.convert_to_hash(list, name_without_brackets: true, simplify: true)
                  change_value(hash)
                  @old_value = hash
                  mutate
                end
              end
            end
          end

          def layout_input
            DIV(class: 'row') do
              DIV(class: 'col') do
                DIV(class: 'form-group') do
                  LABEL do
                    I18n.t('activerecord.attributes.dynamic/form/element/base.filters')
                  end
                  yield
                end
              end
            end
          end

        end
      end
    end
  end
end


