describe Dynamic::Knewsletter::Feature do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @contact = @schema.klasses.create!(name: 'Contact')

    @feature = @schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
    @communication_feature = @schema.features.find_by(name: 'Dynamic::Communication::Feature')
    @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @contact)
    @communication_feature.update!(enabled: true)
    @recipient_info_feature = @schema.features.find_by(name: 'Dynamic::RecipientInfo::Feature')
  end

  it 'should raise if RecipientInfo feature is disabled' do
    expect{@feature.update!(enabled: true)}.to raise_error{ActiveRecord::RecordInvalid}
    expect(@feature.errors.details[:enabled]).to contain_exactly(
      include(
        error: :dependent,
        name: @recipient_info_feature.human_name,
      )
    )
  end

  context 'when enabled' do
    before(:each) do
      @recipient_info_feature.update!(enabled: true)
    end

    it 'does add associations on Recipient klass' do
      @feature.update!(enabled: true)
      expect(@schema.klasses.where(name: 'RecipientEmailAddress').first.associations.map(&:name)).to include('visits', 'newsletter_deliveries')
    end

    context 'Newsletter' do

      context 'when newsletter klass missing' do

        it 'does create a Newsletter klass' do
          expect(@schema.klasses.map(&:name)).to_not include('Newsletter')
          @feature.update(enabled: true)
          expect(@schema.klasses.map(&:name)).to include('Newsletter')
        end
      end

      context 'when newsletter klass existing' do
        before(:each) do
          @newsletter = @schema.klasses.create!(
            name: 'Newsletter',
          )
        end

        it 'does not create another Newsletter klass' do
          expect {
            @feature.update!(enabled: true)
          }.to change {
            @schema.klasses.count
          }.by(4)
        end

        it 'does add associations on Newsletter Klass' do
          expect(@newsletter.associations.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'Newsletter').first.associations.map(&:name)).to include('links')
          expect(@schema.klasses.where(name: 'Newsletter').first.associations.map(&:name)).not_to include('recipients')
          expect(@schema.klasses.where(name: 'Newsletter').first.associations.map(&:name)).to include('deliveries')
        end

        it 'does add attributes on Newsletter Klass' do
          expect(@newsletter.attrs.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'Newsletter').first.attrs.count).to eq(11)
        end
      end
    end

    context 'NewsletterLink' do
      context 'when link klass missing' do

        it 'does create a Link klass' do
          expect(@schema.klasses.map(&:name)).to_not include('NewsletterLink')
          @feature.update(enabled: true)
          expect(@schema.klasses.map(&:name)).to include('NewsletterLink')
        end
      end

      context 'when link klass existing' do
        before(:each) do
          @link = @schema.klasses.create!(
            name: 'NewsletterLink',
          )
        end

        it 'does not create another Link klass' do
          expect {
            @feature.update!(enabled: true)
          }.to change {
            @schema.klasses.count
          }.by(4)
        end

        it 'does add associations on Link klass' do
          expect(@link.associations.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'NewsletterLink').first.associations.map(&:name)).to include('newsletter')
          expect(@schema.klasses.where(name: 'NewsletterLink').first.associations.map(&:name)).to include('visits')
        end

        it 'does add attributes on Link Klass' do
          expect(@link.attrs.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'NewsletterLink').first.attrs.count).to eq(7)
        end
      end
    end

    context 'NewsletterVisit' do

      context 'When Visit Klass missing' do
        it 'does create a recipient klass' do
          expect(@schema.klasses.map(&:name)).to_not include('NewsletterVisit')
          @feature.update(enabled: true)
          expect(@schema.klasses.map(&:name)).to include('NewsletterVisit')
        end
      end

      context 'When visit klass existing' do
        before(:each) do
          @visit = @schema.klasses.create!(
            name: 'NewsletterVisit',
          )
        end

        it 'does not create another Visit klass' do
          expect {
            @feature.update!(enabled: true)
          }.to change {
            @schema.klasses.count
          }.by(4)
        end

        it 'does add associations on Visit klass' do
          expect(@visit.associations.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'NewsletterVisit').first.associations.map(&:name)).to include('recipient')
          expect(@schema.klasses.where(name: 'NewsletterVisit').first.associations.map(&:name)).to include('link')
        end

        it 'does add attributes on Visit Klass' do
          expect(@visit.attrs.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'NewsletterVisit').first.attrs.count).to eq(1)
        end
      end
    end

    context 'NewsletterDelivery' do

      context 'when delivery klass missing' do

        it 'does create a Delivery klass' do
          expect(@schema.klasses.map(&:name)).to_not include('NewsletterDelivery')
          @feature.update(enabled: true)
          expect(@schema.klasses.map(&:name)).to include('NewsletterDelivery')
        end
      end

      context 'when delivery klass existing' do
        before(:each) do
          @delivery = @schema.klasses.create!(
            name: 'NewsletterDelivery',
          )
        end

        it 'does add associations on Delivery Klass' do
          expect(@delivery.associations.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'NewsletterDelivery').first.associations.map(&:name)).to include('recipient')
          expect(@schema.klasses.where(name: 'NewsletterDelivery').first.associations.map(&:name)).to include('newsletter')
        end

        it 'does add attributes on Delivery Klass' do
          expect(@delivery.attrs.count).to eq(0)
          @feature.update!(enabled: true)
          expect(@schema.klasses.where(name: 'NewsletterDelivery').first.attrs.count).to eq(2)
        end
      end
    end

    context 'NewsletterTheme' do
      before(:each) do
        @account = @schema.klasses.create!(
          name: 'Account',
        )
        @email = @schema.klasses.detect {|k| k.name == 'Email'}
      end

      it 'does create a themes klass' do
        expect(@schema.klasses.map(&:name)).to_not include('NewsletterTheme')
        @feature.update(enabled: true)
        expect(@schema.klasses.map(&:name)).to include('NewsletterTheme')
      end

      it 'does add attribute on Theme Klass' do
        @feature.update!(enabled: true)
        theme_klass = @schema.klasses.detect{|k| k.name == 'NewsletterTheme'}
        expect(theme_klass.attrs.count).to eq(1)
      end

      it 'should add associations' do
        @feature.options.detect{|o| o.name == 'theme_associations_klasses'}.update!(value: [@contact, @account])
        @feature.update!(enabled: true)

        expect(@contact.associations.map(&:name)).to include('newsletter_themes')
        expect(@account.associations.map(&:name)).to include('newsletter_themes')
        expect(@email.associations.map(&:name)).to_not include('newsletter_themes')
      end
    end
  end
end
