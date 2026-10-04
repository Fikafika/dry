module RSpec
  module HyperResource
    module ActiveStorage

      def build_attachment(filename)
        attachment = ::HyperResource::ActiveStorage::Attachment.new(
          signed_id: "12344321",
          filename: filename,
          content_type: content_type(filename)
        )

        attachment.file = file_fixture(filename)

        attachment
      end

      def add_attachment_one(attachment_one, file_fixture_name)
        attachment_one.attachment = build_attachment(file_fixture_name)
      end

      def add_attachment_to_many(attachment_many, file_fixture_name)
        attachment_many.attachments << build_attachment(file_fixture_name)
      end

      def build_blob(filename)

        if RUBY_ENGINE == 'opal'
          return `new Blob(["content"], {type : "#{content_type(filename)}"})`
        else
          f = ::Tempfile.new('file.txt')
          f.write('content')
          return f
        end
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


module HyperResource
  module ActiveStorage; extend ActiveSupport::Concern
    class Attached < ::HyperResource::Base

      # to use active storage for ruby engine
      def related_records
        []
      end
    end
  end
end