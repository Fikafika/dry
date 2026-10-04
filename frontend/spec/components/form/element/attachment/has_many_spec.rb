describe 'Form::Element::Attachment::HasMany', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        def self.api_path
          '/contacts'
        end
        has_many_attached :documents
      end
    end
  end

  context 'mode = edit_in_place' do
    context 'requirement = optional'

    context 'requirement = mandatory' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'D::Uneek::Contact',
            mode: 'edit_in_place',
            elements: [
              {
                id: 1,
                requirement: 'mandatory',
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                attribute_name: 'documents',
                normalized_input_prefix: 'contact@0',
                type: 'Attachment::HasMany',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                id: 1,
                documents: {attachments: [{signed_id: 'XXXX', filename: 'file.txt', content_type: 'application/text'}]}
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'submit should fail if value is not present' do
        find('.form-control').click
        find('.fa-trash').click
        find('.btn', text: 'Terminer').click
        expect(page).to have_selector('.fa-times')
      end
    end

  end

end


