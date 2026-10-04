describe Dynamic::MailHosting::SyncState, elasticsearch: false, sidekiq: false do
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

    @UniqueEmail = @schema.klasses.detect {|k| k.name == 'RecipientEmailAddress'}

    @feature.options.detect{|o| o.name == 'associations_klasses'}.update!(value: [@Contact, @Account])
    @feature.update!(enabled: true)
  end

  describe '.sync' do
    before(:each) do
      @Message = @feature.concerns.detect{|c| c.name == 'Message'}.klass
      stub_request(:any, "#{ENV['UNEEK_MAIL_APP_PROTOCOL']}://#{ENV['UNEEK_MAIL_APP_HOST']}")
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

    context 'single page sync' do
      before(:each) do
        @message_id = SecureRandom.uuid

        stub_messages_filter(
          body: {
            'scope_a' => [
              {
                'id' => @message_id,
                'sender' => { 'email_address' => 'noreply@lelapin.fr' },
                'recipients' => [
                  { 'email_address' => 'titi@lelapin.fr' },
                  { 'email_address' => 'tata@lelapin.fr' }
                ],
                'subject' => 'Bonjour CRM',
                'sent_at' => '2026-02-19T18:30:00Z',
                'imap_id' => 'imap-001'
              }
            ],
            'scope_b' => [
              {
                'id' => @message_id,
                'sender' => { 'email_address' => 'noreply@lelapin.fr' },
                'recipients' => [{ 'email_address' => 'titi@lelapin.fr' }],
                'subject' => 'Bonjour CRM',
                'sent_at' => '2026-02-19T18:30:00Z',
                'imap_id' => 'imap-001'
              }
            ]
          }
        )
      end

      it 'should create messages' do
        Dynamic::MailHosting::SyncState.sync
        expect(@Message.const.first).to have_attributes(
          subject: 'Bonjour CRM',
          sent_at: DateTime.parse('2026-02-19T18:30:00Z'),
          imap_id: 'imap-001',
        )
      end

      it 'imports de-duplicated messages' do
        expect { Dynamic::MailHosting::SyncState.sync }.to change { @Message.const.count }.from(0).to(1)
      end

      it 'associates recipients to the message' do
        Dynamic::MailHosting::SyncState.sync

        message = @Message.const.find_by(subject: 'Bonjour CRM')
        expect(message).not_to be_nil

        to_association_id = @Message.associations.find_by(name: 'recipients')&.id
        expect(to_association_id).not_to be_nil

        recipient_email_ids = @schema.const_assoc_klass.where(
          association_owner_type: @Message.const.name,
          association_owner_id: message.id,
          association_target_type: @UniqueEmail.const.name,
          schema_association_type: 'Dynamic::Schema::Association::Base',
          schema_association_id: to_association_id,
          deleted_at: nil
        ).pluck(:association_target_id)

        recipient_addresses = @UniqueEmail.const.where(id: recipient_email_ids).pluck(:address)
        expect(recipient_addresses).to match_array(['titi@lelapin.fr', 'tata@lelapin.fr'])
      end
    end

    context 'paginated sync' do
      before(:each) do
        @first_id = SecureRandom.uuid
        @second_id = SecureRandom.uuid

        stub_messages_filter(
          body: {
            'scope_page_1' => [
              {
                'id' => @first_id,
                'sender' => { 'email_address' => 'noreply@lelapin.fr' },
                'recipients' => [{ 'email_address' => 'first@lelapin.fr' }],
                'subject' => 'Page one message',
                'sent_at' => '2026-02-19T18:30:00Z',
                'imap_id' => 'imap-page-1'
              }
            ],
            'pagination' => {
              'has_more' => true,
              'next_cursor' => 'cursor-2'
            }
          }
        )

        stub_messages_filter(
          cursor: 'cursor-2',
          body: {
            'scope_page_2' => [
              {
                'id' => @second_id,
                'sender' => { 'email_address' => 'noreply@lelapin.fr' },
                'recipients' => [{ 'email_address' => 'second@lelapin.fr' }],
                'subject' => 'Page two message',
                'sent_at' => '2026-02-19T18:35:00Z',
                'imap_id' => 'imap-page-2'
              }
            ],
            'pagination' => {
              'has_more' => false,
              'next_cursor' => nil
            }
          }
        )
      end

      it 'imports messages from all pages' do
        expect { Dynamic::MailHosting::SyncState.sync }.to change { @Message.const.count }.from(0).to(2)
        expect(@Message.const.all.map(&:subject)).to match_array(['Page one message', 'Page two message'])
      end
    end

    context 're-sync with same message id' do
      before(:each) do
        @message_id = SecureRandom.uuid

        stub_messages_filter(
          body: {
            'scope_first_sync' => [
              {
                'id' => @message_id,
                'sender' => { 'email_address' => 'noreply@lelapin.fr' },
                'recipients' => [{ 'email_address' => 'update@lelapin.fr' }],
                'subject' => 'Old subject',
                'sent_at' => '2026-02-19T18:30:00Z',
                'imap_id' => 'imap-update-1'
              }
            ]
          }
        )
      end

      it 'does not duplicate existing message' do
        Dynamic::MailHosting::SyncState.sync
        expect(@Message.const.count).to eq(1)
        expect(@Message.const.first.subject).to eq('Old subject')

        stub_messages_filter(
          body: {
            'scope_second_sync' => [
              {
                'id' => @message_id,
                'sender' => { 'email_address' => 'noreply@lelapin.fr' },
                'recipients' => [{ 'email_address' => 'update@lelapin.fr' }],
                'subject' => 'Old subject',
                'sent_at' => '2026-02-19T18:45:00Z',
                'imap_id' => 'imap-update-2'
              }
            ]
          }
        )

        expect { Dynamic::MailHosting::SyncState.sync }.not_to change { @Message.const.count }
        expect(@Message.const.first.subject).to eq('Old subject')
      end
    end
  end
end
