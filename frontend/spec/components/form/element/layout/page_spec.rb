describe 'Form::Element::Layout::Page', type: :system do
  before(:each) do
    page_exec do
      class Record < HyperResource::Base
      end
    end
  end

  context 'record' do

    context 'form with two pages' do
      before(:each) do
        mount do
          Form(record: Record.new) do
            Form::Element::Layout::Page() do
              Form::Element::Attribute::String(attribute_name: 'attr')
              Form::Element::Control::Navigation()
            end
            Form::Element::Layout::Page() do
              Form::Element::Attribute::String(attribute_name: 'attr2')
              Form::Element::Control::Navigation()
            end
          end
        end
      end

      it 'should render elements of first page' do
        expect(
          has_css?('input[name="record[attr]"]')
        ).to eq true

        expect(
          has_content?('Suivant')
        ).to eq true

        expect(
          has_css?('input[name="record[attr2]"]')
        ).to eq false
      end

      it 'fill input and click on next button should render elements of second page' do
        find('input[name="record[attr]"]').set('A') # enable next button
        find('.btn', text: 'Suivant').click

        expect(
          has_css?('input[name="record[attr2]"]')
        ).to eq true

        expect(
          has_content?('Enregistrer')
        ).to eq true
      end

    end

    context 'dynamic_form' do
      before(:each) do

        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'input',
            elements: [
              {
                id: 1,
                type: 'Layout::Page',
              },
              {
                id: 2,
                parent_id: 1,
                klass_name: 'Record',
                root_klass_name: 'record',
                method_names: [],
                attribute_name: 'attr',
                normalized_input_prefix: 'record@0',
                type: 'Attribute::String',
              },
              {
                id: 3,
                parent_id: 1,
                type: 'Control::Navigation',
              },
              {
                id: 4,
                type: 'Layout::Page',
              },
              {
                id: 5,
                parent_id: 4,
                klass_name: 'Record',
                root_klass_name: 'record',
                method_names: [],
                attribute_name: 'attr2',
                normalized_input_prefix: 'record@0',
                type: 'Attribute::String',
              },
              {
                id: 6,
                parent_id: 4,
                type: 'Control::Navigation',
              },
            ],
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should render elements of first page' do
        expect(
          has_css?('input[name="record[attr]"]')
        ).to eq true

        expect(
          has_content?('Suivant')
        ).to eq true

        expect(
          has_css?('input[name="record[attr2]"]')
        ).to eq false
      end

      it 'fill input and click on next button should render elements of second page' do
        find('input[name="record[attr]"]').set('A') # enable next button
        find('.btn', text: 'Suivant').click

        expect(
          has_css?('input[name="record[attr2]"]')
        ).to eq true

        expect(
          has_content?('Enregistrer')
        ).to eq true
      end
    end

  end
end
