# frozen_string_literal: true

class RenameMailHostingMessageKlass < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load

      f = schema.features.find_by(name: "Dynamic::MailHosting::Feature")

      next unless f && f.enabled

      m = f&.options&.detect{|o| o.name == "message_klass"}&.value

      next unless m

      m.update!(
        name: 'MailHostingMessage',
        permalink: 'mail_hosting_message',
      )
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load

      f = schema.features.find_by(name: "Dynamic::MailHosting::Feature")

      next unless f && f.enabled

      message_klass = f.options.detect{|o| o.name == "message_klass"}&.value

      next unless message_klass

      message_klass.update!(name: 'Message', permalink: 'message') if message_klass.name == 'MailHostingMessage'
    end
  end
end
