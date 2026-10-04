class FormulaLanguageServer
  class Connection < ::ActionCable::Connection::Base
    def parse_context_from_params
      @schema_name = env['action_dispatch.request.path_parameters'][:schema_name].classify_permalink
      @klass_name = env['action_dispatch.request.path_parameters'][:klass_name].classify
      @schema = Dynamic::Schema.load(@schema_name)
      @context = "D::#{@schema_name}::#{@klass_name}".safe_constantize

      @context.connection if @context
    end

    def allow_request_origin?
      return true
    end

    def formula_class
      Dynamic::Formula
    end
  end
end