describe Dynamic::PhoneData::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    @schema = Dynamic::Schema.create!(name: 'my')
    @phone_klass = @schema.klasses.create!(name: 'Phone', attrs_attributes: [name: 'number', type: 'String'])

    @feature = @schema.features.find_by(name: 'Dynamic::PhoneData::Feature')
    @options = [
      {
        name: 'phone_number',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        type: 'String',
        value: @phone_klass.attrs.first
      },
      {
        name: 'carrier_attribute',
        type: 'Boolean',
        value: true
      },
      {
        name: 'timezone_association',
        type: 'Boolean',
        value: false
      },
      {
        name: 'category_association',
        type: 'Boolean',
        value: false
      },
      {
        name: 'locality_attribute',
        type: 'Boolean',
        value: true
      }
    ]
  end

  context 'option for attributes' do
    before(:each) do
      @concern = @feature.concerns.find_or_create_by!(name: 'Owner', klass: @phone_klass)
      @concern.options.create!(@options)
    end

    it 'should create attributes for phone klass' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        @phone_klass.attrs.reload.select {|a| a.name == 'phone_carrier'}.length
      }.by(1).and change{
        @phone_klass.attrs.reload.select {|a| a.name == 'phone_locality'}.length
      }.by(1)
    end
  end

  context 'category_association option' do
    before(:each) do
      @options[3][:value] = true
      @concern = @feature.concerns.find_or_create_by!(name: 'Owner', klass: @phone_klass)
      @concern.options.create!(@options)
    end

    it 'should create PhoneCategory klass' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Schema::Klass.where(name: 'PhoneCategory').count
      }.from(0).to(1)
    end

    it 'should create layout and forms' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Layout.where(klass_name: 'D::My::PhoneCategory').count
      }.by(3).and change{
        Dynamic::Form.where(klass_name: 'D::My::PhoneCategory').count
      }.by(2)
    end

    xit 'should create records for PhoneCategory and index them', elasticsearch: true, sidekiq: true do
      ::Dynamic::Elasticsearch.wait_for_complete do
        @feature.update!(enabled: true) # FIXME wait for jobs' batch to complete
      end
      expect(D::My::PhoneCategory.count).to eq(Phonelib::Core::TYPES_DESC.count)
      expect(OpenSearch::Model.client.count(index: D::My::PhoneCategory.__opensearch__.index_name)['count']).to eq(D::My::PhoneCategory.count)
    end

    it 'should create association for phone klass' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        @phone_klass.reload.associations.select {|a| a.name == 'phone_categories'}.count
      }.by(1)
    end
  end

  context 'timezone_association option' do
    before(:each) do
      @options[2][:value] = true
      @concern = @feature.concerns.find_or_create_by!(name: "Owner", klass: @phone_klass)
      @concern.options.create!(@options)
    end

    it 'should raise if Country feature is disabled' do
      expect{@feature.update!(enabled: true)}.to raise_error{ActiveRecord::RecordInvalid}
      expect(@feature.errors.details[:enabled]).to contain_exactly(
        include(
          error: :dependent,
          name: @schema.features.find_by(name: 'Dynamic::Timezone::Feature').human_name,
        )
      )
    end

    context 'Country feature enabled' do
      before(:each) do
        @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)
        @schema.features.find_by(name: 'Dynamic::Timezone::Feature').update!(enabled: true)
      end

      it 'should create associations for phone klass' do
        expect{
          @feature.update(enabled: true)
        }.to change{
          @phone_klass.associations.reload.count
        }.by(1)
      end
    end
  end

  context 'all options' do
    before(:each) do
      @options[2][:value] = true
      @options[3][:value] = true
      @concern = @feature.concerns.find_or_create_by!(name: 'Owner', klass: @phone_klass)
      @concern.options.create!(@options)
      @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)
      @schema.features.find_by(name: 'Dynamic::Timezone::Feature').update!(enabled: true)
    end

    context 'create phone_number' do
      before(:each) do
        @feature.update!(enabled: true)
        @phone = D::My::Phone.create(number: '+33612345678')
      end

      it 'should fill attributes' do
        expect(@phone).to have_attributes(
          phone_locality: nil,
          phone_carrier: 'SFR',
        )
      end

      it 'should fill associations' do
        expect(D::My::PhoneCategory.count).to eq(Phonelib::Core::TYPES_DESC.length)
        expect(D::My::Timezone.count).to eq(1)
        expect(@phone.phone_categories.first.label_en).to eq('Mobile')
        expect(@phone.timezones.first.tz_id).to eq('Europe/Paris')
      end

      it 'should not duplicate associations with same label' do
        D::My::Phone.create(number: '+33687654321')
        expect(D::My::PhoneCategory.count).to eq(Phonelib::Core::TYPES_DESC.length)
        expect(D::My::Timezone.count).to eq(1)
      end

      context 'update from other timezone' do
        before(:each) do
          @phone.update!(number: '+11234567890')
        end

        it 'should remove old timezones from association' do
          expect(@phone.timezones.reload.length).to be > 0
          expect(@phone.timezones).to_not include(D::My::Timezone.first)
        end

        it 'should not delete timezone record' do
          expect(D::My::Timezone.first.tz_id).to eq('Europe/Paris')
        end
      end

      context 'update invalid number' do
        before(:each) do
          @phone.update!(number: '+1234567890')
        end

        it 'should remove incorrect timezones from association' do
          expect(@phone.timezones.reload).to be_empty
        end
      end

      context 'update number to other phone_category' do
        before(:each) do
          @phone.update!(number: '+33378123456')
        end

        it 'should remove incorrect phone_categories from association' do
          expect(@phone.timezones.reload.length).to be > 0
          expect(@phone.timezones).to_not include(D::My::PhoneCategory.find_by(label_en: 'Mobile'))
        end
      end

      context 'wrong timezone identifier' do
        before(:each) do
          @feature.update!(enabled: true)
          @wrong_phone = D::My::Phone.create!(
            number: '+33612345678',
            phone_carrier: 'Orange',
            timezones_attributes: [
              {tz_id: 'wrong timezone'},
            ]
          )
        end

        it 'should replace invalid data' do
          expect(@wrong_phone.phone_carrier).to eq('SFR')
          expect(@wrong_phone.timezones.count).to eq(1)
          expect(@wrong_phone.timezones.first.tz_id).to eq('Europe/Paris')
        end
      end
    end

    context 'synchronizing existing phones' do
      before(:each) do
        D::My::Phone.create!(
          [
            {number: '+33612345678'},
            {number: '+33621342567'},
            {number: '+33698681623'},
          ]
        )
      end

      xcontext 'enable', sidekiq: true do
        before(:each) do
          @feature.update!(enabled: true) # FIXME wait for jobs' batch to complete
        end

        it 'should assign attributes' do
          expect(D::My::Phone.first.phone_carrier).to_not be_nil
        end

        it 'should assign associations' do
          D::My::Phone.all.each do |tel|
            expect(tel.timezones).to_not be_empty
            expect(tel.phone_categories).to_not be_empty
          end
        end
      end
    end
  end
end
