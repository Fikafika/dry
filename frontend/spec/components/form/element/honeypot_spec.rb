describe 'Form::Element::Honeypot', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        attribute :name
      end
    end
  end

  before(:each) do
    mount do
      dynamic_form = Dynamic::Form.new(
        id: 1,
        klass_name: 'Contact',
        mode: 'input',
        elements: [
          {
            id: 1,
            klass_name: 'Contact',
            root_klass_name: 'Contact',
            method_names: [],
            attribute_name: 'name',
            normalized_input_prefix: 'contact@0',
            type: 'Attribute::String',
          },
        ],
        serialized_record_for_input_prefix: {
          'contact@0': {
            name: 'Toto'
          },
        },
      )
      dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
      Form(dynamic_form: dynamic_form)
    end
  end

  it 'should display a honey pot element' do
    expect(page).to have_selector('[name="a_comment_body"]', visible: :hidden)
  end

  xit 'should fill submission when changing honeypot' do
    find('[name="a_comment_body"]', visible: :hidden).set('SPAM') # TODO impossible to interact with hidden elements with selenium driver

    expect(
      page_eval do
        Form.current.submission.params.to_n
      end
    ).to eq({
      'a_comment_body' => 'SPAM',
    })
  end
end
