class Crm
  class Sheet
    class Datatable < ::HyperComponent

      include Hyperstack::Router::Helpers
      include ::Router::Resources
      include ::Crm::Routes::Helpers

      param :schema_name
      param :klass_name
      param :record_id
      param :columns, default: []
      param :width, default: {}
      param :locked, default: nil
      param :order, default: nil
      param :association_name, default: nil
      collect_other_params_as :other_params

      track_changes :record_id, :association_name

      after_new_params do
        if @search_query.nil? || record_id_changed? || association_name_changed?
          init
        end
      end

      render { content }

      def klass
        "D::#{schema_name.classify_permalink}".safe_constantize&.const_get_by_route_key(klass_name)
      end

      def inverse_association
        klass.reflect_on_association(association_name)&.options.try(:[], :inverse_of)
      end

      def inverse_klass
        klass.reflect_on_association(association_name)&.klass
      end

      def init
        if inverse_association
          init_filters = {inverse_association => {"contains_id" => record_id}}
        else
          init_filters = {}
        end
        @search_query_filters = {
          filters: init_filters,
          table: {
            columns: columns,
            width: width,
            locked: locked,
            order: order,
          },
        }
        @search_query = SearchQuery.new(@search_query_filters)
      end

      def content
        if inverse_association
          DIV(class: "container-fluid") do
            Crm::Datatable(
              id: "crm_sheet_datatable",
              klass: inverse_klass,
              draw: @draw,
              search_query: @search_query,
              scroll_y: 300,
            )
          end
        end
      end

      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Sheet::Datatable'

        def apply(params, options = {})
          request = options[:layout_params][:request]
          schema = ::Dynamic::Schema.load(request.params[:schema])
          association_name = schema.attr_or_assoc_or_attach_by_id[options[:schema_association]]&.name

          result = {
            schema_name: request.params[:schema],
            klass_name: request.params[:klass],
            record_id: request.params[:id],
            association_name: association_name,
          }

          return result
        end
      end

    end
  end
end
