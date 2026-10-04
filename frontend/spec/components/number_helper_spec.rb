describe 'NumberHelper', type: :system do

  describe '#number_to_percentage' do
    it 'should add % after an inbreakable space' do
      expect(
        page_eval do
          NumberHelper.number_to_percentage(10)
        end
      ).to eq '10 %'
    end
  end

  describe '#number_to_currency' do
    it 'should add currency and round 2 digit after coma' do
      page_exec do
        I18n.locale = :fr
      end

      expect(
        page_eval do
          NumberHelper.number_to_currency(10, {currency: 'EUR'})
        end
      ).to eq '10,00 €'
    end
  end

end
