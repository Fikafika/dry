class Crm
  class Sheet
    class Versions < HyperComponent

      param :path
      param :side

      collect_other_params_as :other_params

      render do
        DIV(class: "d-flex flex-row#{'-reverse' if side == "left"} align-items-center") do
          Crm::Sheet::CloseButton(side: side)
        end
        if schema.loaded?
          RecordVersions(record_type: record_type, record_id: record_id)
        end
      end

      def record_id
        request.params[:id]
      end

      def request
        return @request if @request && @previous_path == path
        @previous_path = path
        @request = ::Router::Resources::Request.new(path)
        return @request
      end

      def record_type
        schema.klasses&.detect{|k| k.route_key == request.params[:klass]}&.const_absolute_name
      end

      def schema_name
        request.params[:schema].classify_permalink
      end

      def schema
        observe @schema ||= Dynamic::Schema.load(schema_name)
      end

    end
  end
end
