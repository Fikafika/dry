module RSpec
  module ActiveStorage
    module Helper
      extend ActiveSupport::Concern

      def attach_fixture_file(attachment, filename)
        attachment.attach(fixture_file_upload(file_fixture(filename), content_type(filename)))
      end

      private

      def content_type(filename)
        extension = filename.split('.').last

        case extension
        when 'txt'
          content_type = 'text/plain'
        when 'jpg'
          content_type = 'image/jpeg'
        when 'png'
          content_type = 'image/png'
        when 'pdf'
          content_type = 'application/pdf'
        else
          content_type = 'application/octet-stream'
        end
      end
    end
  end
end