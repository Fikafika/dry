describe 'Form::Element::Attribute::SerializedArray', type: :system do
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
          Form(record: Record.new(attr: ['A1', 'B1'])) do
            Form::Element::Attribute::SerializedArray(attribute_name: 'attr', possible_values: [{label: 'A1', value: 'A1', options: [{label: 'B1', value: 'B1'}]}])
          end
        end
      end

      it 'open dropdown should display items of first level' do
        find('.fa-chevron-down').click
        expect(page).to have_content('A1')
        expect(page).to_not have_content('B1')
      end

      it 'should not expand when click on option' do
        find('.fa-chevron-down').click
        find('span', text: 'A1').click
        expect(page).to_not have_content('B1')
      end

      it 'should expand when click on arrow' do
        find('.fa-chevron-down').click
        find('.fa-chevron-right').click
        expect(page).to have_content('B1')
      end

    end

    describe 'selectable_expandable_option = false' do
      before(:each) do
        mount do
          Form(record: Record.new(attr: ['A1', 'B1'])) do
            Form::Element::Attribute::SerializedArray(attribute_name: 'attr', possible_values: [{label: 'A1', value: 'A1', options: [{label: 'B1', value: 'B1'}]}], selectable_expandable_option: false)
          end
        end
      end

      it 'should expand when click on option' do
        find('.fa-chevron-down').click
        find('span', text: 'A1').click
        expect(page).to have_content('B1')
      end

      it 'should expand when click on arrow' do
        find('.fa-chevron-down').click
        find('.fa-chevron-right').click
        expect(page).to have_content('B1')
      end

    end

  end
end
