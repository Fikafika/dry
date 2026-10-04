describe 'Form::Element::Attribute::DateTime', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        attribute :last_connected_at#, type: DateTime
      end
    end
  end

  context 'form.mode = input' do

    context 'dynamic' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Contact',
            elements: [
              {
                id: 1,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'last_connected_at',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::DateTime',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                last_connected_at: '2023-01-10T23:00:00.000Z'
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display an input date' do
        expect(page).to have_selector('input[type="datetime-local"][name="contact[last_connected_at]"]')
      end

      it 'should open a date picker when click in input' do
        find('input[type="datetime-local"][name="contact[last_connected_at]"]').click
        # why Selenium::WebDriver::Error::MoveTargetOutOfBoundsError when click on the calendar ?
        # TODO find a real way
      end

      it 'should change date when click in datetime picker' do
        find('input[type="datetime-local"][name="contact[last_connected_at]"]')
        #find('input[type="datetime-local"][name="contact[last_connected_at]"]').set(DateTime.parse('2023-01-11T23:00:00.000Z')) # capybara doesn't trigger change :(
        find('input[type="datetime-local"][name="contact[last_connected_at]"]').send_keys('11') # keystrokes

        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq({
          'contact@0' => { 'last_connected_at' => '2023-01-11T23:00:00+00:00' }, # same as 2023-01-11T23:00:00.000Z
        })
      end
    end

    context 'record' do
      before(:each) do
        mount do
          Form(record: Contact.new(last_connected_at: '2023-01-11T23:00:00.000Z')) do
            Form::Element::Attribute::DateTime(attribute_name: 'last_connected_at')
          end
        end

      end

      it 'should display an input date' do
        expect(page).to have_selector('input[type="datetime-local"][name="contact[last_connected_at]"]')
      end

      it 'should open a date picker when click in input' do
        find('input[type="datetime-local"][name="contact[last_connected_at]"]').click
        # why Selenium::WebDriver::Error::MoveTargetOutOfBoundsError when click on the calendar ?
        # TODO find a real way
      end

      it 'should change date when click in date picker' do
        find('input[type="datetime-local"][name="contact[last_connected_at]"]')
        #find('input[type="datetime-local"][name="contact[last_connected_at]"]').set(DateTime.parse('2023-01-11')) # capybara doesn't trigger change :(
        find('input[type="datetime-local"][name="contact[last_connected_at]"]').send_keys('11') # keystrokes

        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq({
          'contact' => { 'last_connected_at' => '2023-01-11T23:00:00+00:00' }, # same as 2023-01-11T23:00:00.000Z
        })
      end

    end

  end

  context 'form.mode = edit_in_place' do

    context 'dynamic' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Contact',
            mode: 'edit_in_place',
            elements: [
              {
                id: 1,
                mode: 'edit_in_place',
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                method_names: [],
                attribute_name: 'last_connected_at',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::DateTime',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                last_connected_at: '2023-01-10T23:00:00.000Z'
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display a fake input with a datetime' do
        expect(page).to have_content('10/01/2023 23:00:00')
      end

      it 'should display an input datetime-local when clicked' do
        find('.form-control').click
        expect(page).to have_selector('input[type="datetime-local"]')
      end

    end



  end

end
