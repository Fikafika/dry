describe 'Crm::Index', type: :system do

  describe 'ChangeLayout' do
    before(:each) do
      page_exec do
        extend Crm::Index::ChangeLayout
      end
    end

    describe '#has_l_in_rison?' do
      it 'should be true if rison contains quote' do
        expect(
          page_eval do
            has_l_in_rison?("http://dynamo.dev.localhost/crm/uneek/table/contacts?_(l:'019ad93d-90b4-71aa-9edb-35fb2d0fecff')")
          end
        ).to eq true
      end

      it 'should be true if rison contains %27' do
        expect(
          page_eval do
            has_l_in_rison?("http://dynamo.dev.localhost/crm/uneek/table/contacts?_(l:%27019ad93d-90b4-71aa-9edb-35fb2d0fecff%27)")
          end
        ).to eq true
      end

      it "should be false doesn't have a key l" do
        expect(
          page_eval do
            has_l_in_rison?("http://dynamo.dev.localhost/crm/uneek/table/contacts?_(a:a)")
          end
        ).to eq false
      end
    end

    describe '#replace_l_in_rison' do
      it 'should replace when url contains quote' do
        expect(
          page_eval do
            replace_l_in_rison(
              "http://dynamo.dev.localhost/crm/uneek/table/contacts?_(l:'019ad93d-90b4-71aa-9edb-35fb2d0fecff')",
              "019ed09d-d850-779a-8c72-f87fe0dec4d0",
            )
          end
        ).to eq "http://dynamo.dev.localhost/crm/uneek/table/contacts?_(l:'019ed09d-d850-779a-8c72-f87fe0dec4d0')"
      end

      it 'should replace when url contains %27' do
        expect(
          page_eval do
            replace_l_in_rison(
              "http://dynamo.dev.localhost/crm/uneek/table/contacts?_(l:%27019ad93d-90b4-71aa-9edb-35fb2d0fecff%27)",
              "019ed09d-d850-779a-8c72-f87fe0dec4d0"
            )
          end
        ).to eq "http://dynamo.dev.localhost/crm/uneek/table/contacts?_(l:%27019ed09d-d850-779a-8c72-f87fe0dec4d0%27)"
      end
    end

  end
end
