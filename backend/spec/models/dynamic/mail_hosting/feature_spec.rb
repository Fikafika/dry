describe Dynamic::MailHosting::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @community = Community.create!(name: 'my', permalink: 'my')
    @schema = @community.schema

    @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
    @Account = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])

    @feature = @schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
  end

  it 'should raise when RecipientInfo feature is disabled' do
    expect{@feature.update!(enabled: true)}.to raise_error {ActiveRecord::RecordInvalid}
  end

  describe '.after_enabled' do
    before(:each) do
      @communication_feature = @schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
      @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @Contact)
      @communication_feature.update!(enabled: true)
      @recipient_info_feature = @schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      @recipient_info_feature.update!(enabled: true)
    end

    it 'should create Message klass' do
      @feature.update!(enabled: true)
      expect(@feature.concerns.detect {|c| c.name == 'Message'}.klass).to be
    end

    it 'should create Message associations' do
      @feature.update!(enabled: true)
      message_klass = @feature.concerns.detect {|c| c.name == 'Message'}.klass
      expect(message_klass.associations.map(&:name)).to contain_exactly('sender', 'recipients', 'carbon_copy', 'blind_carbon_copy', 'receivers')
    end

    it 'should create RecipientEmailAddress associations' do
      @feature.update!(enabled: true)
      unique_email_klss = @recipient_info_feature.concerns.detect {|c| c.name == 'EmailAddress'}.klass
      message_klass = @feature.concerns.detect {|c| c.name == 'Message'}.klass
      messages_assoc = unique_email_klss.associations.detect { |a| a.name == 'messages' }
      expect(messages_assoc.type).to eq('HasMany')
      expect(messages_assoc.target_klass_id).to eq(message_klass.id)
    end

    context 'default associations' do
      before(:each) do
        @feature.options.detect {|o| o.name == 'associations_klasses'}.update!(value: [@Contact])
      end

      it 'should create associations on target klasses' do
        @feature.update!(enabled: true)
        expect(@Contact.associations.map(&:name)).to include('default_recipient', 'default_cc', 'default_bcc')
      end

      context 'sheet tabs' do
        before(:each) do
          @feature.update!(enabled: true)
        end

        it 'should create layout element for messages associations' do
          message_klass = @feature.concerns.detect {|c| c.name == 'Message'}.klass
          @message_contact_association = @Contact.associations.detect{|a| a.target_klass_id == message_klass.id }
          message_tab_count = ::Dynamic::Layout::Element
            .joins(:layout)
            .where(
              dynamic_layouts: {
                schema_id: @Contact.schema_id,
                klass_name: @Contact.const_absolute_name,
                default: true,
              }
            )
            .where(component: 'Crm::Sheet::TabBar::Tab')
            .where(["component_params::json->>'association_id'=?", @message_contact_association.id])
            .count
          expect(message_tab_count).to eq(1)
        end

        it 'should create layout elements for each default associations' do
          default_associations_ids = Dynamic::MailHosting::Feature::DEFAULT_EMAIL_ASSOCIATION_ATTRS.map do |a|
            @Contact.associations.detect {|assoc| assoc.name == a[:name]}.id
          end

          default_association_tab_count = ::Dynamic::Layout::Element
            .joins(:layout)
            .where(
              dynamic_layouts: {
                schema_id: @Contact.schema_id,
                klass_name: @Contact.const_absolute_name,
                default: true,
              }
            )
            .where(component: 'Crm::Sheet::TabBar::Tab')
            .where("component_params::json->>'association_id' IN ('#{default_associations_ids.join("', '")}')")
            .count

          expect(default_association_tab_count).to eq(default_associations_ids.count)
        end
      end
    end
  end

  describe '.after_disabled' do
    before(:each) do
      @communication_feature = @schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
      @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @Contact)
      @communication_feature.update!(enabled: true)
      @recipient_info_feature = @schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      @recipient_info_feature.update!(enabled: true)
    end

    context 'with associations_klasses filled' do
      before(:each) do
        @feature.options.detect{|o| o.name == 'associations_klasses'}.update!(value: [@Contact])
        @feature.update!(enabled: true)
      end

      context 'sheet tabs' do
        before(:each) do
          @feature.update!(enabled: false)
        end

        it 'should remove layout element for messages associations' do
          message_klass = @feature.concerns.detect {|c| c.name == 'Message'}.klass
          @message_contact_association = @Contact.associations.detect{|a| a.target_klass_id == message_klass.id }
          message_tab_count = ::Dynamic::Layout::Element
            .joins(:layout)
            .where(
              dynamic_layouts: {
                schema_id: @Contact.schema_id,
                klass_name: @Contact.const_absolute_name,
                default: true,
              }
            )
            .where(component: 'Crm::Sheet::TabBar::Tab')
            .where(["component_params::json->>'association_id'=?", @message_contact_association.id])
            .count
          expect(message_tab_count).to eq(0)
        end

        it 'should remove layout elements for each default associations' do
          default_associations_ids = Dynamic::MailHosting::Feature::DEFAULT_EMAIL_ASSOCIATION_ATTRS.map do |a|
            @Contact.associations.detect {|assoc| assoc.name == a[:name]}.id
          end

          default_association_tab_count = ::Dynamic::Layout::Element
            .joins(:layout)
            .where(
              dynamic_layouts: {
                schema_id: @Contact.schema_id,
                klass_name: @Contact.const_absolute_name,
                default: true,
              }
            )
            .where(component: 'Crm::Sheet::TabBar::Tab')
            .where("component_params::json->>'association_id' IN ('#{default_associations_ids.join("', '")}')")
            .count

          expect(default_association_tab_count).to eq(0)
        end
      end
    end
  end
end
