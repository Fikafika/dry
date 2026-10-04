describe 'Form::Element::Attribute::Time', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        attribute :wakeup_time
      end
    end
  end

  context 'form.mode = input' do

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
                attribute_name: 'wakeup_time',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::Time',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                wakeup_time: '07:00:00'
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display an input date' do
        expect(page).to have_selector('input[type="time"][name="contact[wakeup_time]"]')
      end

      it 'should open a picker when click in input' do
        find('input[type="time"][name="contact[wakeup_time]"]').click
        # why Selenium::WebDriver::Error::MoveTargetOutOfBoundsError when click on the calendar ?
        # TODO find a real way
      end

      it 'should change date when click in date picker' do
        find('input[type="time"][name="contact[wakeup_time]"]')
        #find('input[type="time"][name="contact[wakeup_time]"]').set(DateTime.parse('2023-01-11T23:00:00.000Z')) # capybara doesn't trigger change :(
        find('input[type="time"][name="contact[wakeup_time]"]').send_keys('11') # keystrokes

        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq({
          'contact@0' => { 'wakeup_time' => '11:00:00' },
        })
      end
    end

    context 'record' do
      before(:each) do
        mount do
          Form(record: Contact.new(wakeup_time: '07:00:00')) do
            Form::Element::Attribute::Time(attribute_name: 'wakeup_time')
          end
        end

      end

      it 'should display an input date' do
        expect(page).to have_selector('input[type="time"][name="contact[wakeup_time]"]')
      end

      it 'should open a date picker when click in input' do
        find('input[type="time"][name="contact[wakeup_time]"]').click
        # why Selenium::WebDriver::Error::MoveTargetOutOfBoundsError when click on the calendar ?
        # TODO find a real way
      end

      it 'should change date when click in date picker' do
        find('input[type="time"][name="contact[wakeup_time]"]')
        #find('input[type="time"][name="contact[wakeup_time]"]').set(DateTime.parse('11:00:00')) # capybara doesn't trigger change :(
        find('input[type="time"][name="contact[wakeup_time]"]').send_keys('11') # keystrokes

        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq({
          'contact' => { 'wakeup_time' => '11:00:00' },
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
                attribute_name: 'wakeup_time',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::Time',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                wakeup_time: '08:00:00'
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display a fake input with a date' do
        expect(page).to have_content('08:00:00')
      end

      it 'should display an input time when clicked' do
        find('.form-control').click
        expect(page).to have_selector('input[type="time"]')
      end

    end

  end

end
