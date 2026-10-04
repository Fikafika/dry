# frozen_string_literal: true

::DocumentConverter.configure do |config|
  config.client_name = ENV.fetch('CLIENT_NAME'){'dynamo'}
  config.remote_host = ENV.fetch('JODCONVERTER_HOST'){'docconv'}
  config.remote_port = ENV.fetch('JODCONVERTER_PORT'){3000}
  config.timeout = ENV.fetch('JODCONVERTER_TIMEOUT'){2*60}
  config.logger = Logger.new('log/document_converter.log')
end
