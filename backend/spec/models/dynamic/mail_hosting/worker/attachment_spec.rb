describe Dynamic::MailHosting::Worker::Attachment, elasticsearch: false, sidekiq: false do
  before(:each) do
    @community = Community.create!(name: 'my', permalink: 'my')
    @schema = @community.schema

    @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
    @Account = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])

    @feature = @schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}

    @communication_feature = @schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
    @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @Contact)
    @communication_feature.update!(enabled: true)
    @recipient_info_feature = @schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
    @recipient_info_feature.update!(enabled: true)

    @feature.options.detect{|o| o.name == 'associations_klasses'}.update!(value: [@Contact, @Account])
    @feature.update!(enabled: true)

    @UniqueEmail = @recipient_info_feature.concerns.detect {|c| c.name == 'RecipientEmailAddress'}
    @Email = @communication_feature.concerns.detect {|k| k.name == 'Email'}.klass
    @Message = @feature.concerns.detect {|c| c.name == 'Message'}.klass
  end

  let(:endpoint){"#{ENV['UNEEK_MAIL_APP_PROTOCOL']}://#{ENV['UNEEK_MAIL_APP_HOST']}/api/email/messages/filter"}

  def stub_messages_filter(body:, cursor: nil)
    request = stub_request(:post, endpoint).with(query: hash_including({'community_id' => @community.uneek_sso_uuid}))

    request = request.with do |req|
      parsed_body = JSON.parse(req.body)
      has_expected_base = parsed_body['limit'] == 50 && parsed_body.dig('rules', 'all_messages', 'sent_at', 'gt').is_a?(Array)

      if cursor.present?
        has_expected_base && parsed_body['cursor'] == cursor
      else
        has_expected_base && !parsed_body.key?('cursor')
      end
    end

    request.to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )
  end

  context 'attachment recompute job' do
    it 'recomputes attachments asynchronously when messages are synchronized' do
      contact = @Contact.const.create!(name: 'Contact Async Sync')
      contact_email = @Email.const.create!(address: 'phase2@lelapin.fr')
      contact.emails << contact_email

      rules_klass = "D::#{@schema.name}::R::MailHosting::Rule".safe_constantize
      rules_klass.create!(
        klass_name: @Contact.const.name,
        name: 'Rule async sync attachment',
        conditions_attributes: [
          {
            attr: 'recipients',
            operator: 'includes',
            value: '"phase2@lelapin.fr"'
          }
        ]
      )

      message_id = SecureRandom.uuid

      sync_state_klass = "D::#{@schema.name}::R::MailHosting::SyncState".safe_constantize
      sync_state = sync_state_klass.first_or_create!
      sync_state.update!(rules_signature: Dynamic::MailHosting::SyncState.send(:rules_signature_for_schema, @schema))

      stub_messages_filter(
        body: {
          'scope_a' => [
            {
              'id' => message_id,
              'sender' => { 'email_address' => 'noreply@lelapin.fr' },
              'recipients' => [{ 'email_address' => 'phase2@lelapin.fr' }],
              'subject' => 'trigger',
              'sent_at' => '2026-02-19T19:10:00Z',
              'imap_id' => 'imap-phase2-sync'
            }
          ]
        }
      )

      endpoint = "#{ENV['UNEEK_MAIL_APP_PROTOCOL']}://#{ENV['UNEEK_MAIL_APP_HOST']}/api/email/messages/filter"
      stub_request(:post, endpoint)
        .with(query: hash_including({ 'community_id' => @community.uneek_sso_uuid }))
        .with do |req|
          parsed_body = JSON.parse(req.body)
          parsed_body['rules'].is_a?(Hash) && parsed_body['rules'].key?(contact.id)
        end
        .to_return(
          'status' => 200,
          'headers' => { 'Content-Type' => 'application/json' },
          body: {
            contact.id => [
              {
                'id' => message_id,
                'sender' => { 'email' => 'noreply@lelapin.fr' },
                'recipients' => [{ 'email' => 'phase2@lelapin.fr' }],
                'subject' => 'trigger',
                'sent_at' => '2026-02-19T19:10:00Z'
              }
            ]
          }.to_json
        )

      allow(Dynamic::MailHosting::Worker::Attachment).to receive(:perform_async).and_wrap_original do |_method, schema_id|
        Dynamic::MailHosting::Worker::Attachment.new.perform(schema_id)
      end

      Dynamic::Elasticsearch.wait_for_complete do
        Dynamic::MailHosting::SyncState.sync
      end

      associations = @schema.const_assoc_klass.where(
        association_owner_type: @Contact.const.name,
        association_owner_id: contact.id,
        association_target_type: @Message.const.name,
        deleted_at: nil
      ).pluck(:association_target_id)

      expect(associations).to include(message_id)
    end

    it 'recomputes attachments asynchronously when rules signature changes' do
      contact = @Contact.const.create!(name: 'Contact Async Signature')
      contact_email = @Email.const.create!(address: 'signature@lelapin.fr')
      contact.emails << contact_email

      message = @Message.const.create!(id: SecureRandom.uuid, subject: 'signature trigger')

      rules_klass = "D::#{@schema.name}::R::MailHosting::Rule".safe_constantize
      rules_klass.create!(
        klass_name: @Contact.const.name,
        name: 'Rule async signature attachment',
        conditions_attributes: [
          {
            attr: 'sender',
            operator: 'includes',
            value: '"signature@lelapin.fr"'
          }
        ]
      )

      sync_state_klass = "D::#{@schema.name}::R::MailHosting::SyncState".safe_constantize
      sync_state = sync_state_klass.first_or_create!
      sync_state.update!(rules_signature: 'stale-signature')

      stub_messages_filter(body: {})

      endpoint = "#{ENV['UNEEK_MAIL_APP_PROTOCOL']}://#{ENV['UNEEK_MAIL_APP_HOST']}/api/email/messages/filter"
      stub_request(:post, endpoint)
        .with(query: hash_including({ 'community_id' => @community.uneek_sso_uuid }))
        .to_return(
          'status' => 200,
          'headers' => { 'Content-Type' => 'application/json' },
          body: {
            contact.id => [
              {
                'id' => message.id,
                'sender' => { 'email' => 'signature@lelapin.fr' },
                'recipients' => [{ 'email' => 'other@lelapin.fr' }],
                'subject' => 'signature trigger',
                'sent_at' => '2026-02-19T19:10:00Z'
              }
            ]
          }.to_json
        )

      allow(Dynamic::MailHosting::Worker::Attachment).to receive(:perform_async).and_wrap_original do |_method, schema_id|
        Dynamic::MailHosting::Worker::Attachment.new.perform(schema_id)
      end

      Dynamic::Elasticsearch.wait_for_complete do
        Dynamic::MailHosting::SyncState.sync
      end

      associations = @schema.const_assoc_klass.where(
        association_owner_type: @Contact.const.name,
        association_owner_id: contact.id,
        association_target_type: @Message.const.name,
        deleted_at: nil
      ).pluck(:association_target_id)

      expect(associations).to include(message.id)
    end

    it 'recomputes parent associations from rule-filtered messages' do
      contact = @Contact.const.create!(name: 'Contact Rule')
      contact_email = @Email.const.create!(address: 'phase2.rule@lelapin.fr')
      contact.emails << contact_email

      message_kept = @Message.const.create!(id: SecureRandom.uuid, subject: 'Kept message')
      message_ignored = @Message.const.create!(id: SecureRandom.uuid, subject: 'Ignored message')

      rules_klass = "D::#{@schema.name}::R::MailHosting::Rule".safe_constantize
      rule = rules_klass.create!(
        klass_name: @Contact.const.name,
        name: 'Rule driven attachment',
        conditions_attributes: [
          {
            attr: 'recipients',
            operator: 'includes',
            value: '"phase2.rule@lelapin.fr"'
          }
        ]
      )

      allow(rule).to receive(:messages_for).and_return(
        {
          contact.id => [
            {
              'id' => message_kept.id,
              'recipients' => [{ 'email' => 'phase2.rule@lelapin.fr' }]
            }
          ]
        }
      )
      allow(rules_klass).to receive(:includes).with(:conditions).and_return([rule])

      Dynamic::MailHosting::Worker::Attachment.new.recompute_parent_associations_from_rules(@feature.reload)

      associations = @schema.const_assoc_klass.where(
        association_owner_type: @Contact.const.name,
        association_owner_id: contact.id,
        association_target_type: @Message.const.name,
        deleted_at: nil
      ).pluck(:association_target_id)

      expect(associations).to include(message_kept.id)
      expect(associations).not_to include(message_ignored.id)
    end

    it 'attaches message when contact email matches sender' do
      contact = @Contact.const.create!(name: 'Contact Sender')
      contact_email = @Email.const.create!(address: 'sender.match@lelapin.fr')
      contact.emails << contact_email

      message_sent = @Message.const.create!(id: SecureRandom.uuid, subject: 'Sender based message')

      rules_klass = "D::#{@schema.name}::R::MailHosting::Rule".safe_constantize
      rule = rules_klass.create!(
        klass_name: @Contact.const.name,
        name: 'Rule sender attachment',
        conditions_attributes: [
          {
            attr: 'sender',
            operator: 'includes',
            value: '"sender.match@lelapin.fr"'
          }
        ]
      )

      allow(rule).to receive(:messages_for).and_return(
        {
          contact.id => [
            {
              'id' => message_sent.id,
              'sender' => { 'email' => 'sender.match@lelapin.fr' },
              'recipients' => [{ 'email' => 'other@lelapin.fr' }]
            }
          ]
        }
      )
      allow(rules_klass).to receive(:includes).with(:conditions).and_return([rule])

      Dynamic::MailHosting::Worker::Attachment.new.recompute_parent_associations_from_rules(@feature.reload)

      associations = @schema.const_assoc_klass.where(
        association_owner_type: @Contact.const.name,
        association_owner_id: contact.id,
        association_target_type: @Message.const.name,
        deleted_at: nil
      ).pluck(:association_target_id)

      expect(associations).to include(message_sent.id)
    end

    it 'imports missing messages during recompute before attaching' do
      contact = @Contact.const.create!(name: 'Contact Import')
      contact_email = @Email.const.create!(address: 'import.match@lelapin.fr')
      contact.emails << contact_email

      missing_message_id = SecureRandom.uuid

      rules_klass = "D::#{@schema.name}::R::MailHosting::Rule".safe_constantize
      rule = rules_klass.create!(
        klass_name: @Contact.const.name,
        name: 'Rule import attachment',
        conditions_attributes: [
          {
            attr: 'sender',
            operator: 'includes',
            value: '"import.match@lelapin.fr"'
          }
        ]
      )

      allow(rule).to receive(:messages_for).and_return(
        {
          contact.id => [
            {
              'id' => missing_message_id,
              'sender' => { 'email' => 'import.match@lelapin.fr' },
              'recipients' => [{ 'email' => 'other@lelapin.fr' }],
              'subject' => 'Imported by recompute',
              'sent_at' => '2026-02-20T08:00:00Z'
            }
          ]
        }
      )
      allow(rules_klass).to receive(:includes).with(:conditions).and_return([rule])

      expect {
        Dynamic::MailHosting::Worker::Attachment.new.recompute_parent_associations_from_rules(@feature.reload)
      }.to change {
        @Message.const.where(id: missing_message_id).count
      }.from(0).to(1)

      associations = @schema.const_assoc_klass.where(
        association_owner_type: @Contact.const.name,
        association_owner_id: contact.id,
        association_target_type: @Message.const.name,
        deleted_at: nil
      ).pluck(:association_target_id)

      expect(associations).to include(missing_message_id)
    end
  end
end
