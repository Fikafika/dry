class Crm
  class Sheet
    class Toolbar < ::Crm::Base

      param :side
      param :record
      param :title, default: nil

      collect_other_params_as :other_params

      render do
        DIV(class: "d-flex flex-row#{'-reverse' if side == "left"} align-items-center") do
          Crm::Sheet::CloseButton(side: side)
          if title
            H5(class: "my-0 flex-grow-1 text-center") {title}
          else
            DIV(class: "flex-grow-1") {}
          end
          Crm::Sheet::Menu(record: record, side: side) if record && !record.new_record?
        end
      end

      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Sheet::Toolbar'

        def apply(params, options = {})
          return {
            side: options[:layout_params][:side],
            record: (dynamic_klass(params[:schema], params[:klass]).new(id: params[:id]) rescue nil),
          }
        end
      end
    end
  end
end
