Rails.application.configure do
  options = {
    address: ENV['MAIL_SERVER_ADDRESS'],
    port: ENV['MAIL_SERVER_PORT'],
    domain: ENV['MAIL_SERVER_DOMAIN'],
    user_name: ENV['MAIL_SERVER_USERNAME'].present? ? ENV['MAIL_SERVER_USERNAME'] : nil,
    password: ENV['MAIL_SERVER_PASSWORD'].present? ? ENV['MAIL_SERVER_PASSWORD'] : nil,
    authentication: ENV['MAIL_SERVER_AUTHENTICATION'].present? ? ENV['MAIL_SERVER_AUTHENTICATION'] : nil,
  }
  options[:enable_starttls_auto] = ENV['MAIL_ENABLE_STARTTLS_AUTO'].present?
  options[:openssl_verify_mode] = ENV['MAIL_OPENSSL_VERIFY_MODE'] if ENV['MAIL_OPENSSL_VERIFY_MODE'].present?
  options[:ssl] = true if ENV['MAIL_SERVER_SSL'].present?
  config.action_mailer.smtp_settings = options
end

if Rails.env.development?
  class DevMailerInterceptor
    def self.delivering_email(message)
      message.to = [ENV['DYNAMO_EMAIL_DEV']]
    end
  end

  ActionMailer::Base.register_interceptor(DevMailerInterceptor)
end
