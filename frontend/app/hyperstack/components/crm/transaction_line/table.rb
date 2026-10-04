require 'uneek_formatting'

class Crm
  module TransactionLine
    class Table < HyperComponent
      include UneekFormatting::NumberHelper

      param :record_id
      param :record_klass
      param :lines_association
      param :columns, default: []
      param :group_column
      param :position_column
      param :amount_excluding_vat_attribute
      param :amount_including_vat_attribute
      param :vat_breakdown_attribute
      param :discount_and_fee_summary_attribute
      param :currency_association

      collect_other_params_as :other_params

      track_changes :record_id

      render do
        DIV(class: other_params[:className]) do
          next unless record&.loaded?

          Crm::DatatableWithRowGroup(
            id: "transaction-lines#{record_id}",
            ajax: ajax,
            klass: klass,
            columns: columns,
            group_column: group_column,
            position_column: position_column,
            currency: currency,
            additional_cell_lines: {
              label: [
                {
                  css_class: 'text-info',
                  value_retriever: name_retriever(['compute_fees_and_discounts', 'discounts']),
                }, {
                  css_class: 'text-info',
                  value_retriever: name_retriever(['compute_fees_and_discounts', 'fees'])
                }
              ],
              gross_unit_price: [
                {
                  css_class: 'text-info',
                  value_retriever: computed_value_retriever(
                    ['compute_fees_and_discounts', 'discounts', 'computed_value']
                  ),
                }, {
                  css_class: 'text-info',
                  value_retriever: computed_value_retriever(
                    ['compute_fees_and_discounts', 'fees', 'computed_value']
                  ),
                }
              ],
            }
          ).on(:row_reorder) do |positions, reload|
            record_klass.new(id: record_id).update("#{lines_association}_attributes": positions).then do
              reload.call
              mutate
            end
          end
          DIV(class: 'mt-3') do
            Summary(
              record_id: record_id,
              record_klass: record_klass,
              lines_association: lines_association,
              amount_excluding_vat_attribute: amount_excluding_vat_attribute,
              amount_including_vat_attribute: amount_including_vat_attribute,
              vat_breakdown_attribute: vat_breakdown_attribute,
              discount_and_fee_summary_attribute: discount_and_fee_summary_attribute,
              currency_association: currency_association,
            )
          end
        end
      end

      private

      def record
        return unless record_klass && record_id
        record_klass.update_cache(['find']) if record_id_changed?
        return observe record_klass.includes(record_includes).find(record_id)
      end

      def record_includes
        {currency_association => 1}
      end

      def ajax
        includes = includes_from_column_names
        inverse_assoc = record_klass.reflect_on_association(lines_association)&.options&.[]('inverse_of')
        scope = klass.includes(includes).where("#{inverse_assoc}_id": record_id).per(1000).scope
        url = klass.collection_path(scope)
        return {
          url: url,
          type: "GET",
        }
      end

      def klass
        record_klass.reflect_on_association(lines_association)&.klass # TransactionLine
      end

      def includes_from_column_names
        result = {}

        columns.each do |col|
          col_name = col[:name]
          if klass.attributes[col_name].nil?
            result[:include] ||= {}
            result[:include][col_name] ||= 1
            next
          end
          next unless col_name&.include?('.')
          j = result

          path = col_name.split('.')
          path.each_with_index do |p, i|
            a = p.gsub('[]', '')
            if i != path.length - 1
              j[a] = {} if j[a] == 1
              j[a] ||= {}
              j[a][:include] ||= {}
              j = j[a][:include]
            else
              j[a] ||= 1
            end
          end
        end

        result[:include] ||= {}
        result[:include][:compute_fees_and_discounts] = 1

        return result
      end

      def computed_value_retriever(path)
        return lambda do |row, col|
          next dig_in_row(row, col, path)
        end
      end

      def dig_in_row(row, col, path) # beurk
        v = row
        path.each_with_index do |p, i|
          v = v.JS[p]
          return unless v
          if `Array.isArray(#{v})`
            r = []
            p_ = path[(i + 1)..-1]
            Array(v).each do |e|
              j = dig_in_row(e, col, p_)
              r << j
            end
            if r.compact.any?
              return r
            else
              return nil
            end
          end
        end
        if `typeof #{v} === 'undefined'`
          return nil
        else
          return v
        end
      end

      def name_retriever(path)
        c = currency
        return lambda do |row, col|
          names = dig_in_row(row, col, path + ['name'])
          percents = dig_in_row(row, col, path + ['percent'])|| []
          raw_values = dig_in_row(row, col, path + ['raw_value']) || []
          result = []
          names&.each_with_index do |n, i|
            if v = percents[i]
              v = number_to_x100_percentage(v, strip_insignificant_zeros: true)
            else
              v = raw_values[i]
              v = number_to_currency(v, currency: c, precision: 2)
            end
            result << "#{n} (#{v})"
          end
          next result
        end
      end

      def currency
        record.send(currency_association)&.iso_code
      end

      class ParamsConverter < ::Layout::ParamsConverter
        include ::UrlHelper

        converter_for 'Crm::TransactionLine::Table'

        def apply(params, options = {})
          request = options[:layout_params][:request]
          schema = ::Dynamic::Schema.load(request.params[:schema])
          record_klass = schema.const.const_get_by_route_key(request.params[:klass])
          record_id = request.params[:id]
          return {
            record_id: record_id,
            record_klass: record_klass,
          }
        end

      end
    end
  end
end
