class Crm
  module Query
    module Table
      class Filters < Form::Element::Base

        param :klass

        render { content }

        def render_input
          return unless klass

          observe klass.options_for_indexed_json
          layout_input do
            if klass.options_for_indexed_json.loaded?
              value = form.submission.read(path)
              if @list.blank? || value != @old_value
                value = nil if value == {}
                @list = ::Crm::Filters::AdvancedList.convert_from_hash(value, klass, name_without_brackets: true, normalize: true)
                @old_value = value
              end
              ::Crm::Filters::AdvancedList(list: @list, klass: klass, root_klass: klass).on(:change) do |list|
                @list = list
                hash = ::Crm::Filters::AdvancedList.convert_to_hash(list, name_without_brackets: true, simplify: true)
                change_value(hash)
                @old_value = hash
                mutate
              end
            end
          end
        end

        def displayed_label
          super || I18n.t('crm.query.params.table.filters')
        end

      end
    end
  end
end
