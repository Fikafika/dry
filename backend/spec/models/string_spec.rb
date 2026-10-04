describe String, elasticsearch: false, sidekiq: false do

  describe ClassifyPermalink do

    describe '#classify_permalink' do

      it 'should convert from permalink' do
        expect('logement-solidaire-63'.classify_permalink).to eq 'LogementSolidaire63'
        expect('cnam-entreprises'.classify_permalink).to eq 'CnamEntreprises'
      end

      it 'should convert from underscore' do
        expect('logement_solidaire63'.classify_permalink).to eq 'LogementSolidaire63'
        expect('cnam_entreprises'.classify_permalink).to eq 'CnamEntreprises'
      end

      it 'should not convert when already converted' do
        expect('LogementSolidaire63'.classify_permalink).to eq 'LogementSolidaire63'
        expect('CnamEntreprises'.classify_permalink).to eq 'CnamEntreprises'
      end

    end

    describe '#modulify_permalink' do
      it 'should convert from name with dash' do
        expect('dynamic-formula'.modulify_permalink).to eq 'Dynamic::Formula'
      end
    end

  end

end

