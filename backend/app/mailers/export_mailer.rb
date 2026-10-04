class ExportMailer < ApplicationMailer

  layout 'mailer'

  def result_email(from, to, cc, subject, body, options = {})
    options[:attachments].each do |name, attachment|
      attachments[name] = attachment
    end if options[:attachments]
    mail(from: from, to: to, cc: cc, subject: subject, body: body)
  end

end