describe Community, elasticsearch: false, sidekiq: false do

  describe 'create' do

    context 'no existing schema' do

      it 'should create schema using name as permalink' do
        expect{
          Community.create!(name: 'Uneek', permalink: 'uneek')
        }.to change {
          Dynamic::Schema.count
        }.by(1)
        expect(Dynamic::Schema.last.name).to eq 'Uneek'
      end

    end

    context 'preexisting schema' do
      before(:each) do
        @schema = Dynamic::Schema.create!(name: 'Uneek')
      end

      it 'should be associated' do
        expect{
          Community.create!(name: 'Uneek', permalink: 'uneek')
        }.to_not change {
          Dynamic::Schema.count
        }

        expect(Community.last.schema).to eq @schema
      end

    end

  end

end
