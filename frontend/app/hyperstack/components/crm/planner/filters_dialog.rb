class Crm
  class Planner
    class FiltersDialog < ::Modal
      param :search_query
      param :klass
      param :query_record
      param :label
      param :filter_name
      param :filter_path

      fires :apply

      def title
        I18n.t('crm.planner.filters.title')
      end

      def body
        DIV(class: 'd-flex flex-column w-100') do
          if query_record
            DIV(class: 'pt-3 overflow-auto') do
              Form(record: query_record, class: 'px-3 pb-3', submission_path: '') do
                Form::Element::Attribute::String(attribute_name: 'path', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'type', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'user_id', editor: 'hidden')
                Form::Element::Attribute::Hash(attribute_name: 'params', mode: 'nested_form') do
                  filter_content
                end
              end.on(:loaded) do |form|
                @form = form
              end
            end
          end
        end
      end

      def footer
        BUTTON(class: 'btn btn-primary', type: 'button') do
          I18n.t('shared.apply')
        end.on(:click) do
          return unless @form
          @form.submit(
            transform_params: ->(params) {
              if params.has_key?(:params)
                cleaned = query_record.class.clean_params(params[:params])
                if cleaned && cleaned.dig(*filter_path)
                  target = filter_path.reduce(search_query) do |sq, key|
                    sq[key] ||= {}
                  end
                  target[filter_name] = cleaned.dig(*filter_path, filter_name)
                end
              end
              params
            }
          ).then do
            close
            apply!
          end
        end
      end

      def filter_content
        build_nested_form(filter_path)
      end

      private

      def build_nested_form(path)
        if path.empty?
          Crm::Query::Table::Filters(
            label: label,
            attribute_name: filter_name,
            klass: klass
          )
        else
          Form::Element::Attribute::Hash(attribute_name: path[0], mode: 'nested_form') do
            build_nested_form(path.slice(1..-1))
          end
        end
      end
    end
  end
end