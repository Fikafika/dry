#https://medium.com/get-on-board-dev/rails-7-breaks-old-signed-messages-f914d7576d75

Rails.application.config.after_initialize do |app|
  sha1_key_generator =
    ActiveSupport::KeyGenerator.new(app.secret_key_base,
                                    iterations: 1000,
                                    hash_digest_class: OpenSSL::Digest::SHA1)
  [
    "ActiveStorage",
  ].each do |verifier|
    app
      .message_verifier(verifier)
      .rotate(sha1_key_generator.generate_key(verifier))
  end
end
