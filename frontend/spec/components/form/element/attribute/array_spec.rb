describe 'Form::Element::Attribute::Array', type: :system do
  before(:each) do
    page_exec do
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
      end
    end
  end

  context 'editor = tree_select' do

    context '' do
      before(:each) do
        mount do
          Form(record: Record.new(attr: [])) do
            Form::Element::Attribute::Array(attribute_name: 'attr', possible_values: [{label: 'A1', value: 'A1', options: [{label: 'B1', value: 'A1.B1'}]}])
          end
        end
      end

      it 'should add an array in submission' do
        find('.fa-chevron-down').click # open dropdown
        expect(page).to have_content('A1')
        expect(page).to have_css('.fa-chevron-right')
        expect(page).to_not have_content('B1')
        find('.fa-chevron-right').click
        expect(page).to have_content('B1')
        find('div[value="A1.B1"]').click
        expect(
          page_eval do
            Form.current.submission.params.dig('record', 'attr')
          end
        ).to eq ['A1', 'B1']
      end

    end

  end
end
