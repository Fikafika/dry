# frozen_string_literal: true

class ReplaceOldSignedIdInDynamicFormElements < ActiveRecord::Migration[8.0]
  def up
    sha1_key_generator =
      ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base,
                                    iterations: 1000,
                                    hash_digest_class: OpenSSL::Digest::SHA1)

    Rails.application.message_verifier("ActiveStorage").rotate(sha1_key_generator.generate_key('ActiveStorage'))

    Dynamic::Form::Element::Base::Translation.where('text LIKE ? AND text LIKE ?', '%=--%', '%blobs%').find_each do |e|
      r = /"(http[^"]*)"/.match(e.text);
      new_text = e.text
      r.captures.each do |url|
        next unless url.include?('blobs')
        old_signed_id = url.split('/')[-2]
        blob = ActiveStorage::Blob.find_signed(old_signed_id)
        unless blob
          puts "can't find blob for #{url}"
          next
        end
        new_url = url.gsub(old_signed_id, blob.signed_id)
        new_text = new_text.gsub(url, new_url)
      end
      if e.text != new_text
        e.update_column(:text, new_text)
      end
    end
  end

  def down
  end
end
