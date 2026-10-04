class Crm
  class Sheet
    class Table < ::HyperComponent

      include Hyperstack::Router::Helpers
      include ::Router::Resources
      include ::Crm::Routes::Helpers

      param :table_columns_attributes
      param :schema_association
      param :nowrap, default: "0"
      param :schema_name
      param :klass_name
      param :record_id
      collect_other_params_as :other_params

      render { content }

      def content
        style = {}
        if nowrap == "1"
          style['whiteSpace'] = "nowrap"
          style['width'] = "1%"
        end
        DIV(class: "container-fluid") do
          DIV(style: {overflowX: "auto"}) do
            TABLE(class: "table table-striped table-bordered", style: {borderCollapse: "separate", borderSpacing: "0"}) do
              THEAD do
                TR do
                  table_columns_attributes.each do |col|
                    TH do
                      col['name']
                    end
                  end
                  TH(class: "bg-body", style: {position:"sticky", right: "0", width: "1%"}) do
                    ''
                  end
                end
              end
              InfiniteScroll(TBODY, items: all_items, show_loader: false) do |dynamic_association|
                record = dynamic_association.association_target
                TR do
                  table_columns_attributes.each do |col|
                    TD(style: style) do
                      record.send(col['column'])
                    end
                  end
                  TD(class: "bg-body", style: {position: "sticky", right: "0", borderLeft: "1px solid", borderColor: "inherit", width: "1%"}) do
                    DIV(style: {display: "inline-flex"}) do
                      IconButton(
                        icon: 'arrow-up-right-from-square',
                        variant: 'transparent-light-yiq',
                        data: {'open-panel': 'opposite'},
                        shape: '',
                        target: edit_url(record.class, record.id),
                      )
                      Crm::Sheet::Item::Menu(
                        record: record,
                        association: dynamic_association
                      )
                    end
                  end
                end
              end
            end
          end
        end
      end

      def all_items
        schema = ::Dynamic::Schema.load(schema_name)
        klass = schema.const.const_get_by_route_key(klass_name)
        record = klass.find(record_id)

        all_items = record.dynamic_associations.merge_where(schema_association_id: schema_association)

        return all_items
      end


      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Sheet::Table'

        def apply(params, options = {})
          request = options[:layout_params][:request]

          result = {
            schema_name: request.params[:schema],
            klass_name: request.params[:klass],
            record_id: request.params[:id],
          }

          return result
        end
      end

    end
  end
end
