describe Dynamic::RecipientInfo::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @contact = @schema.klasses.create!(name: 'Contact')

    @communication_feature = @schema.features.find_by(name: 'Dynamic::Communication::Feature')
    @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @contact)
    @communication_feature.update!(enabled: true)
    @feature = @schema.features.find_by(name: 'Dynamic::RecipientInfo::Feature')
  end

  context 'when enabled' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
    end

    context 'RecipientInfo' do

      it 'should create associations' do
        expect(D::My::RecipientInfo.reflect_on_association(:target).polymorphic?).to be true
      end

      it 'should not create "new" forms' do
        expect(Dynamic::Form.where(klass_name: 'D::My::RecipientInfo', actions: 1).count).to eq(0)
      end

      it 'should create "new" layouts withtout form' do
        expect(Dynamic::Layout.find_by(klass_name: 'D::My::RecipientInfo', actions: 1).elements.count).to eq(4)
        expect(Dynamic::Layout.find_by(klass_name: 'D::My::RecipientInfo', actions: 1).elements.map(&:component)).to_not include('Form')
      end
    end

    context 'RecipientEmailAddress' do
      before(:each) do
        @schema_klass = @schema.klasses.detect {|k| k.name == 'RecipientEmailAddress'}
      end

      it 'should create associations' do
        expect(D::My::RecipientEmailAddress.reflect_on_association(:info).class_name).to eq(D::My::RecipientInfo.name)
        expect(D::My::RecipientEmailAddress.reflect_on_association(:emails).class_name).to eq(D::My::Email.name)
        expect(D::My::Email.reflect_on_association(:recipient).class_name).to eq(D::My::RecipientEmailAddress.name)
      end

      it 'should have uniqueness validation' do
        expect(@schema_klass.validations.map(&:type)).to include('Uniqueness')
      end

      it 'should not create "new" form' do
        expect(Dynamic::Form.where(klass_name: 'D::My::RecipientEmailAddress', actions: 1).count).to eq(0)
      end

      it 'should create "new" layouts withtout form' do
        expect(Dynamic::Layout.find_by(klass_name: 'D::My::RecipientEmailAddress', actions: 1).elements.count).to eq(4)
        expect(Dynamic::Layout.find_by(klass_name: 'D::My::RecipientEmailAddress', actions: 1).elements.map(&:component)).to_not include('Form')
      end

    end

    context 'RecipientPhoneNumber' do
      before(:each) do
        @schema_klass = @schema.klasses.detect {|k| k.name == 'RecipientPhoneNumber'}
      end

      it 'should create associations' do
        expect(D::My::RecipientPhoneNumber.reflect_on_association(:info).class_name).to eq(D::My::RecipientInfo.name)
        expect(D::My::RecipientPhoneNumber.reflect_on_association(:phones).class_name).to eq(D::My::Phone.name)
        expect(D::My::Phone.reflect_on_association(:recipient).class_name).to eq(D::My::RecipientPhoneNumber.name)
      end

      it 'should have uniqueness validation' do
        expect(@schema_klass.validations.map(&:type)).to include('Uniqueness')
      end

      it 'should not create "new" form' do
        expect(Dynamic::Form.where(klass_name: 'D::My::RecipientPhoneNumber', actions: 1).count).to eq(0)
      end

      it 'should create "new" layouts withtout form' do
        expect(Dynamic::Layout.find_by(klass_name: 'D::My::RecipientPhoneNumber', actions: 1).elements.count).to eq(4)
        expect(Dynamic::Layout.find_by(klass_name: 'D::My::RecipientPhoneNumber', actions: 1).elements.map(&:component)).to_not include('Form')
      end

    end

    context 'then disabled' do
      before(:each) do
        @feature.update(enabled: false)
      end

      context 'and then re-enabled' do

        it 'should not duplicate associations' do
          expect{
            @feature.update(enabled: true)
          }.to_not change{
            Dynamic::Schema::Klass.count
          }
        end

        it 'should not duplicate attributes' do
          expect{
            @feature.update(enabled: true)
          }.to_not change{
            Dynamic::Schema::Attribute::Base.count
          }
        end

        it 'should not duplicate associations' do
          expect{
            @feature.update(enabled: true)
          }.to_not change{
            Dynamic::Schema::Klass.count
          }
        end

        it 'should not duplicate forms' do
          expect{
            @feature.update(enabled: true)
          }.to_not change{
            Dynamic::Form.count
          }
        end

        it 'should not duplicate layouts' do
          expect{
            @feature.update(enabled: true)
          }.to_not change{
            Dynamic::Layout.count
          }
        end
      end
    end

  end

end
