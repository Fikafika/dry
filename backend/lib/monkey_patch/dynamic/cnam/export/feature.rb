module Dynamic
  module Cnam
    module Export
      module Feature
        def self.send_email(csv_path)
          recipients = ENV['CNAM_SISCOL_EXPORT_RECIPIENTS']&.split(' ')
          to_recipient = recipients&.shift
          ExportMailer.result_email(
            ENV['DYNAMO_EMAIL_NOREPLY'],
            to_recipient,
            recipients,
            "Export Siscol - #{Date.current.strftime('%d/%m/%Y')}",
            '',
            attachments: {File.basename(csv_path) => File.read(csv_path)}
          ).deliver_now
        end
      end
    end
  end
end