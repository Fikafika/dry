describe 'Form::Element::Control::Navigation', type: :system do
  before(:each) do
    page_exec do
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
      end
    end
  end

  it 'should be possible to sumbit a form with pre-filled inputs without change values' do
    mount do
      Form(record: Record.new) do
        Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'A')
        Form::Element::Control::Navigation(
          show_cancel_button: false,
          show_previous_button: false,
          show_next_button: false,
          show_submit_button: true,
        )
      end
    end


    find('.btn:not(.disabled)')

    expect(
      page_eval{
        Form.current.enabled?
      }
    ).to eq true
  end

  xit 'should not be possible to sumbit a form not pre-filled inputs without change values' do
    # TODO find a way to pass this contradictory test

    mount do
      Form(record: Record.new) do
        Form::Element::Attribute::String(attribute_name: 'attr')
        Form::Element::Control::Navigation(
          show_cancel_button: false,
          show_previous_button: false,
          show_next_button: false,
          show_submit_button: true,
        )
      end
    end


    find('.btn.disabled')

    expect(
      page_eval{
        Form.current.enabled?
      }
    ).to eq false
  end

  context 'two pages with no input on second page' do
    before(:each) do
      mount do
        Form(record: Record.new) do
          Form::Element::Layout::Page() do
            Form::Element::Attribute::String(attribute_name: 'attr')
            Form::Element::Control::Navigation(
              show_cancel_button: false,
              show_previous_button: true,
              show_next_button: false,
              show_submit_button: true,
              submit_button_text: 'Save',
            )
          end
          Form::Element::Layout::Page() do
            Form::Element::Basic::Text(text: 'Second page')
          end
        end
      end

      page_exec do
        $submitted = false
        stub_request(:post, '/records.json').to_return do |request|
          $submitted = true
          if $expected_success
            {
              status: 200,
              body: {
                attr: 'A'
              }.to_json,
            }
          else
            {
              status: 400,
            }
          end
        end
      end
    end

    context 'submit' do
      context 'success' do
        before(:each) do
          page_exec do
            $expected_success = true
          end
        end

        it 'should display second page' do
          find_field('record[attr]').set('A')
          click_button('Save')
          expect(page).to have_content('Second page')
          expect(page_eval{ $submitted }).to eq true
          expect(page).to_not have_css('.alert-danger')
        end
      end

      context 'error' do
        before(:each) do
          page_exec do
            $expected_success = false
          end
        end

        it 'should display first page with an error' do
          find_field('record[attr]').set('A')
          click_button('Save')
          expect(page_eval{ $submitted }).to eq true
          expect(page).to_not have_content('Second page')
          expect(page).to have_css('.alert-danger')
        end
      end
    end

  end

end
