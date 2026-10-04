describe 'Form::Element::Attribute::Enum', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        attribute :civility, type: Integer
        enum(civility: ['mr', 'mrs'])
      end
    end
  end

  context 'dynamic' do
    before(:each) do
      mount do
        dynamic_form = Dynamic::Form.new(
          id: 1,
          klass_name: 'D::Uneek::Contact',
          elements: [
            {
              id: 1,
              klass_name: 'Contact',
              root_klass_name: 'Contact',
              method_names: [],
              attribute_name: 'civility',
              normalized_input_prefix: 'contact@0',
              type: 'Attribute::Enum',
              editor: 'radio',
            },
          ],
          serialized_record_for_input_prefix: {
            'contact@0': {
              civility: 'mrs'
            },
          },
        )
        dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
        Form(dynamic_form: dynamic_form)
      end

    end

    it 'should display radio boxes' do
      expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mr"]')
      expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mrs"][checked]')
    end

    it 'should change value on click' do
      expect(find("input[id='input-contact-civility-value-0']")).to_not be_checked
      expect(find("input[id='input-contact-civility-value-1']")).to be_checked
      find("input[id='input-contact-civility-value-0']").click
      expect(find("input[id='input-contact-civility-value-0']")).to be_checked
      expect(find("input[id='input-contact-civility-value-1']")).to_not be_checked
    end

  end

  context 'record' do
    context 'editor = radio' do
      before(:each) do
        mount do
          Form(record: Contact.new(civility: 'mrs')) do
            Form::Element::Attribute::Enum(attribute_name: 'civility', editor: 'radio')
          end
        end

      end

      it 'should display radio boxes' do
        expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mr"]')
        expect(page).to have_selector('input[type="radio"][name="contact[civility]"][value="mrs"][checked]')
      end
    end

    context 'editor = step' do
      before(:each) do
        page_exec do
          class Record < HyperResource::Base
            enum attr: ["value 1", "value 2", "value 3", "value 4"]
          end
        end
        mount do
          Form(record: Record.new(attr: 'value 1')) do
            Form::Element::Attribute::Enum(attribute_name: 'attr', editor: 'step')
          end
        end
      end

      it 'should find divs : "step-list" and "step-list-item"' do
        expect(page).to have_css('.step-list')
        expect(page).to have_css('.step-list-item')
      end

      it 'should update a value of div.step-item after click on chosen "step"' do
        find('div[class="step-list-text"]', text: 'value 3').click
        expect(find('div[name="record[attr]"]')['value']).to eq('value 3')
      end

      it 'should add a class: "done" to the chosen "step-list-item" and all its previous siblings but no next siblings' do
        find('div[class="step-list-text"]', text: 'value 3').click
        expect(page).to have_selector('div.done > .step-list-text', text: 'value 1')
        expect(page).to have_selector('div.done > .step-list-text', text: 'value 2')
        expect(page).to have_selector('div.done > .step-list-text', text: 'value 3')
        expect(page).not_to have_selector('div.done > .step-list-text', text: 'value 4')
      end

    end

  end

end
