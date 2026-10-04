# frozen_string_literal: true

class AddCoderTypeToMailHostingOptions < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load

      f = schema.features.find_by(name: "Dynamic::MailHosting::Feature")

      next unless f

      ['email_klass', 'message_klass'].each do |option_name|
        option = f.options.find_by(name: option_name)

        next unless option

        klass_id = schema.klasses.find_by(name: option.value)&.id

        option.update!(
          coder_type: 'Dynamic::Schema::Option::Coder::Klass',
          type: 'String',
          value: klass_id.nil? ? '' : klass_id
        )
      end

      option_association = f.options.find_by(name: "associations_klasses")

      next unless option_association

      if option_association.value.present?
        klasses_id = schema.klasses.where(name: option_association.value.split(';')).map(&:id).join(',')
      else
        klasses_id = nil
      end

      option_association.update!(
        coder_type: 'Dynamic::Schema::Option::Coder::Klasses',
        type: 'String',
        value: klasses_id
      )
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load

      f = schema.features.find_by(name: "Dynamic::MailHosting::Feature")

      next unless f

      ['email_klass', 'message_klass'].each do |option_name|
        option = f.options.find_by(name: option_name)

        next unless option

        klass_name = option.value&.name

        option.update!(
          coder_type: nil,
          type: 'String',
          value: klass_name.nil? ? '' : klass_name
        )
      end

      option_association = f.options.find_by(name: "associations_klasses")

      next unless option_association

      klasses_name = option_association.value&.map { |k| k&.name }&.join(';')

      option_association.update!(
        coder_type: nil,
        type: 'String',
        value: klasses_name.present? ? klasses_name : ''
      )
    end
  end
end
