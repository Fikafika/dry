require 'sidekiq'
require 'sidekiq/batch'

module EnableWaitForCompletedJobs

  def enable_wait_for_completed_jobs
    if params[:wait_for_completed_jobs]
      batch = Sidekiq::Batch.new
      batch.on(:complete, Callback, callback_options)
      batch.jobs do
        yield
      end
    else
      yield
    end
  end

  private

  class Callback

    attr_accessor :options
    attr_accessor :schema

    def on_complete(status, options)
      @options = options
      if status.failures == 0
        refresh_elasticsearch_index
      end
      notify
    end

    private

    def refresh_elasticsearch_index
      klass_name =  options['klass_to_refresh_in_elasticsearch']
      # klass_name is the klass that is currently displayed in datatable
      return unless klass_name
      schema
      index_name = klass_name&.safe_constantize.try(:__opensearch__).try(:index_name)
      ::OpenSearch::Model.client.indices.refresh(index: index_name) if index_name
    end

    def schema
      return @schema if @schema
      klass_name =  options['klass_to_refresh_in_elasticsearch'] # TODO use another klass_name
      schema_name = klass_name.to_s.split('::')[1]
      return unless schema_name
      @schema = Dynamic::Schema.load(schema_name)
    end

    def notify
      return unless options['user_id']
      ActionCable.server.broadcast("hyper_resource|completed_jobs|#{options['user_id']}", options)
    end

  end

  def callback_options
    result = params.slice(*callback_param_keys).permit!.to_h
    result['user_id'] = User.current&.id
    return result
  end

  def callback_param_keys
    [
      'callback_id',
      'klass_to_refresh_in_elasticsearch',
    ]
  end

end
