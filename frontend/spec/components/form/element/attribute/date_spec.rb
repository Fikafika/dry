describe 'Form::Element::Attribute::Date', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        attribute :birth_date
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
                attribute_name: 'birth_date',
                normalized_input_prefix: 'contact@0',
                type: 'Attribute::Date',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                birth_date: '2023-01-10'
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display an input date' do
        expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-01-10"]')
      end

      it 'should change date when press keys' do
        find('input[type="date"][name="contact[birth_date]"]').send_keys('1', '1')
        expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-01-10"]') # it does not change because it would reset keystrokes each time value change
        expect(page_eval{ ::Element['input[type="date"][name="contact[birth_date]"]'].val }).to eq '2023-01-11' # but it changes internal value
        expect(page_eval{ Form.current.submission.params.to_n }).to eq({ # and submission
          'contact@0' => { 'birth_date' => '2023-01-11' },
        })
      end

      xit 'should open a date picker when click in input' do
        find('input[type="date"][name="contact[birth_date]"]').click
        # why Selenium::WebDriver::Error::MoveTargetOutOfBoundsError when click on the calendar ?
        # TODO find a real way
      end

      xit 'should change date when click in date picker' do
        find('input[type="date"][name="contact[birth_date]"]')
        #find('input[type="date"][name="contact[birth_date]"]').set(Date.parse('2023-01-11T23:00:00.000Z')) # capybara doesn't trigger change :(
        find('input[type="date"][name="contact[birth_date]"]').send_keys('11') # keystrokes

        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq({
          'contact@0' => { 'birth_date' => '2023-01-11' }, # same as 2023-01-11T23:00:00.000Z
        })
      end

      it 'should update date value when filled by a autocomplete on a belongs_to' do
        page_exec do
          Form.current.submission.write(['contact', 0, 'birth_date'], '2023-02-24') #simulate autocomplete
          Form.current.mutate
        end
        expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-02-24"]')
      end
    end

    context 'record' do
      before(:each) do
        mount do
          Form(record: Contact.new(birth_date: '2023-01-10')) do
            Form::Element::Attribute::Date(attribute_name: 'birth_date')
          end
        end
      end

      it 'should display an input date' do
        expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-01-10"]')
      end

      it 'should change date when press keys' do
        find('input[type="date"][name="contact[birth_date]"]').send_keys('1', '1')
        expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-01-10"]') # it does not change because it would reset keystrokes each time value change
        expect(page_eval{ ::Element['input[type="date"][name="contact[birth_date]"]'].val }).to eq '2023-01-11' # but it changes internal value
        expect(page_eval{ Form.current.submission.params.to_n }).to eq({ # and submission
          'contact' => { 'birth_date' => '2023-01-11' },
        })
      end

      xit 'should open a date picker when click in input' do
        find('input[type="date"][name="contact[birth_date]"]').click
        # why Selenium::WebDriver::Error::MoveTargetOutOfBoundsError when click on the calendar ?
        # TODO find a real way
      end

      xit 'should change date when click in date picker' do
        find('input[type="date"][name="contact[birth_date]"]')
        #find('input[type="date"][name="contact[birth_date]"]').set(Date.parse('2023-01-11T23:00:00.000Z')) # capybara doesn't trigger change :(
        find('input[type="date"][name="contact[birth_date]"]').send_keys('11') # keystrokes

        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq({
          'contact' => { 'birth_date' => '2023-01-11' }, # same as 2023-01-11T23:00:00.000Z
        })
      end

    end

  end

  context 'form.mode = edit_in_place' do

    context 'dynamic' do

      context 'requirement = optional' do
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
                  attribute_name: 'birth_date',
                  normalized_input_prefix: 'contact@0',
                  type: 'Attribute::Date',
                },
              ],
              serialized_record_for_input_prefix: {
                'contact@0': {
                  id: 1,
                  birth_date: '2023-01-10'
                },
              },
            )
            dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
            Form(dynamic_form: dynamic_form)
          end
          page_exec do
            stub_request(:patch, "/contacts/1.json").to_return do |request|
              {
                status: 200,
                body: {
                  id: 1,
                  birth_date: '2023-01-11'
                }.to_json,
              }
            end
          end
        end

        it 'should display a fake input with a date' do
          expect(page).to have_content('10/01/2023')
        end

        it 'should display an input date and focus it when clicked' do
          find('.form-control').click
          expect(page_eval{ ::Element['input[type="date"][name="contact[birth_date]"][value="2023-01-10"]:focus'].length }).to eq 1 # nota: jquery selector because capybara doesn't support :focus css selector
        end

        context 'editing' do
          before(:each) do
            find('.form-control').click
          end

          it 'should change value when press keys' do
            find('input[type="date"][name="contact[birth_date]"]').send_keys('1', '1')
            expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-01-10"]') # it does not change because it would reset keystrokes each time value change
            expect(page_eval{ ::Element['input[type="date"][name="contact[birth_date]"]'].val }).to eq '2023-01-11' # but it changes internal value
            expect(page_eval{ Form.current.submission.params.to_n }).to eq({ # and submission
              'contact@0' => { 'birth_date' => '2023-01-11' },
            })
          end

        end

        it 'should submit'

      end

      context 'requirement = mandatory' do
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
                  requirement: 'mandatory',
                  klass_name: 'Contact',
                  root_klass_name: 'Contact',
                  method_names: [],
                  attribute_name: 'birth_date',
                  normalized_input_prefix: 'contact@0',
                  type: 'Attribute::Date',
                },
              ],
              serialized_record_for_input_prefix: {
                'contact@0': {
                  id: 1,
                  birth_date: '2023-01-10'
                },
              },
            )
            dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
            Form(dynamic_form: dynamic_form)
          end
        end

        it 'submit should fail if value is not present' do
          find('.form-control').click
          expect(page).to have_selector('input[type=date][name="contact[birth_date]"]')
          find('input[type=date][name="contact[birth_date]"]').send_keys(:backspace, :enter)
          expect(page).to have_selector('.fa-times')
        end
      end

    end

  end

  context 'form.mode = edit_cell' do
    before(:each) do
      mount do
        Form(record: Contact.new(birth_date: '2023-01-10'), mode: :edit_cell) do
          Form::Element::Attribute::Date(attribute_name: 'birth_date')
        end
      end
    end

    it 'should display an focused input date' do
      expect(page_eval{ ::Element['input[type="date"][name="contact[birth_date]"][value="2023-01-10"]:focus'].length }).to eq 1
    end

    it 'should change value when press keys' do
      find('input[type="date"][name="contact[birth_date]"]').send_keys('1', '1')
      expect(page).to have_selector('input[type="date"][name="contact[birth_date]"][value="2023-01-10"]') # it does not change because it would reset keystrokes each time value change
      expect(page_eval{ ::Element['input[type="date"][name="contact[birth_date]"]'].val }).to eq '2023-01-11' # but it changes internal value
      expect(page_eval{ Form.current.submission.params.to_n }).to eq({ # and submission
        'contact' => { 'birth_date' => '2023-01-11' },
      })
    end
  end

end
