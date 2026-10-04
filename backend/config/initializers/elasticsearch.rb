unless Rails.env.production?
  logger = Rails.logger.dup.tap do |logger|
    logger.formatter = logger.formatter.dup.tap do |formatter|
      def formatter.call(severity, timestamp, progname, msg)
        super(severity, timestamp, progname, "[opensearch] #{msg}")
      end
    end
  end
end

::OpenSearch::Model.client = ::OpenSearch::Client.new(
  user: ENV.fetch("ES_USER") {"admin"},
  password: ENV.fetch("ES_PASSWORD"),
  url: ENV.fetch('ES_URL') { 'http://opensearch:9200' },
  logger: logger,
)
