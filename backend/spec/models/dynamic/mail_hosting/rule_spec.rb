describe Dynamic::MailHosting::Rule, elasticsearch: false, sidekiq: false do

  before(:each) do
    @community = Community.create!(name: 'my', permalink: 'my')
    @schema = @community.schema
    @feature = @schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}

    @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
    @Account = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])

    @communication_feature = @schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
    @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @Contact)
    @communication_feature.update!(enabled: true)
    @recipient_info_feature = @schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
    @recipient_info_feature.update!(enabled: true)

    @feature.options.detect{|o| o.name == 'associations_klasses'}.update!(value: [@Contact, @Account])
  end

  describe 'load' do

    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
    end

    it 'should commpute eligible classes' do
      expect(@schema.const.klasses_associated_to_message).to include(@Contact.const.to_s, @Account.const.to_s)
    end

    it 'should not validate a rule on Address' do
      expect{D::My::R::MailHosting::Rule.new(name: 'test rule', klass_name: 'D::My::Address', user_sso_id: 'ef45wv6v').validate!}.to raise_error ActiveRecord::RecordInvalid
    end

    it 'should validate a rule on Contact' do
      expect(D::My::R::MailHosting::Rule.new(name: 'test rule', klass_name: 'D::My::Contact', user_sso_id: 'ef45wv6v').valid?).to be true
    end

    it 'should validate a rule on Account' do
      expect(D::My::R::MailHosting::Rule.new(name: 'test rule', klass_name: 'D::My::Account', user_sso_id: 'ef45wv6v').valid?).to be true
    end

    describe 'invalid condition formulas' do

      it 'skips invalid formulas without crashing rule payload generation' do
        contact = @Contact.const.create!(name: 'Contact Formula')

        rule = D::My::R::MailHosting::Rule.create!(
          name: 'Rule with invalid formula',
          klass_name: @Contact.const.name,
          conditions_attributes: [
            {
              attr: 'sender',
              operator: 'includes',
              value: '"lapinou@kakarot.com"'
            },
            {
              attr: 'mailbox',
              operator: 'includes',
              value: '['
            }
          ]
        )

        payload = nil
        expect { payload = rule.send(:rule_for_record, contact) }.not_to raise_error

        expect(payload.dig('sender', 'includes')).to eq(['lapinou@kakarot.com'])
        expect(payload).not_to have_key('mailbox')
      end
    end

  end

end
