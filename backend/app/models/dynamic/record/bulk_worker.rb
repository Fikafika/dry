require 'hash_with_num_keys_to_array'

module Dynamic
  module Record
    class BulkWorker
      include ::Sidekiq::Worker
      include ::Dynamic::Worker
      sidekiq_options queue: 'import', retry: 0 # TODO

      attr_accessor :perform_params
      attr_accessor :progress

      def perform(perform_params)
        @perform_params = perform_params.with_indifferent_access

        with_user do
          with_progress(perform_params) do
            return unless user && klass_name
            in_batches(schema_name, klass_name, batch_size: 100, relation_scope: relation_scope) do |klass, batch|
              apply(batch)
            end
          end
        end
      end

      private

      def with_user
        User.current = user
        yield
      ensure
        User.current = nil
      end

      def with_progress(options)
        @progress = perform_params['progress']

        @success_count = 0
        @error_count = 0

        if progress

          progress.errors << {user: :blank} unless user
          progress.errors << {klass_name: :blank} unless klass_name
          additional_progress_errors
          if progress.errors.any?
            progress.fail
            return
          end

          progress.total = total
          progress.before_finish do
            progress.data[:success_count] = @success_count
            progress.data[:error_count] = @error_count
          end
          progress.start

          yield

          @error_count == 0 ? progress.success : progress.fail
        else
          yield
        end

      end

      def user
        @user ||= ::User.find_by_id(perform_params[:user_id])
      end

      def klass_name
        perform_params[:klass_name]
      end

      def schema_name
        return unless klass_name
        @schema_name ||= klass_name.split('::')[1]
      end

      def total
        result = 0
        load_schema(schema_name) do
          scope = klass
          if scope
            scope = scope_for_permissions(scope)
            scope = relation_scope.call(scope, scope) if relation_scope
            result = scope.count
          end
        end
        return result
      end

      def klass
        @klass ||= klass_name.safe_constantize
      end

      def params
        @params ||= (perform_params[:params] || {}.with_indifferent_access)
      end

      def relation_scope
        return unless scopes_params&.any? || params[:where] || params[:where_not]
        Proc.new do |relation, klass|
          relation = relation.where(params[:where]) if params[:where]
          relation = relation.where.not(params[:where_not]) if params[:where_not]
          scopes_params&.each do |s|
            raise "forbidden scope #{s[:name]}" unless allowed_scopes.include?(s[:name])
            relation = relation.send(s[:name], *s[:args])
          end
          relation
        end
      end

      def scopes_params
        @scopes_params ||= case params['scopes']
          when Hash
            params['scopes']&.with_num_keys_to_array&.map do |h|
              h[:args] = h[:args].with_num_keys_to_array if h[:args].is_a?(Hash)
              h
            end || []
          when Array
            params['scopes']
          end
      end

      def allowed_scopes
        ['where_filters', 'where_query']
      end

      def apply(batch)
        raise 'not implemented'
      end

      def update_progress(success: true, instant: false)
        return unless progress

        if success
          @success_count += 1
        else
          @error_count += 1
        end

        progress.without_latency(instant) do
          progress.current += 1
        end
      end

      def additional_progress_errors
        # can be redefined
      end

      concerning :Permissions do

        def scope_for_permissions(s)
          result = s
          if klass_is_controlled? && !user&.admin?(schema_name)
            if scope_for_action
              u = user || ::UneekPermission::PredefinedReceiver::Public.instance
              result = result.send(scope_for_action, u)
            else
              raise "Permission scope not implemented"
            end
          end
          result
        end

        def klass_is_controlled?
          klass.present? && klass.include?(UneekPermission::ControlledKlass)
        end

        def scope_for_action
          nil
        end

      end

    end
  end
end
