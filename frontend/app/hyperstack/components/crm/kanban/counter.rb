class Crm
    class Kanban
      class Counter < HyperComponent
        param :scope
        param :reload, default: nil

        before_mount do
          @count_obj = nil
          @last_scope_key = nil
          @last_reload = nil
          @last_reported = nil
        end

        render do
          scope_key = scope.scope
          if scope_key != @last_scope_key || reload != @last_reload
            @count_obj = nil
            @last_scope_key = scope_key
            @last_reload = reload
          end

          @count_obj ||= scope.count
          observe @count_obj
          value = @count_obj.to_i

          if @last_reported.nil? || value != @last_reported
            @last_reported = value
          end

          SPAN { value }
        end
      end
    end
  end