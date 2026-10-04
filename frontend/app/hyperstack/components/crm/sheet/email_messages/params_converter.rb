# ParamsConverter for EmailMessages component in Sheet TabBar
class Crm
  class Sheet
    class EmailMessages
      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Sheet::EmailMessages'

        def apply(params, options = {})
          request = options[:layout_params][:request]
          schema = ::Dynamic::Schema.load(request.params[:schema])
          klass = schema.const.const_get_by_route_key(request.params[:klass])
          record = klass.find(request.params[:id])

          # record should be an Email
          # Get messages associated with this email
          messages = record.try(:messages) || []

          result = {
            email: record,
            messages: messages.to_a
          }

          return result
        end
      end
    end
  end
end
