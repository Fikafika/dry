describe 'Form::Element::Attachment::HasOne', type: :system do
  before(:each) do
    page_exec do
      class Contact < HyperResource::Base
        def self.api_path
          '/contacts'
        end
        has_one_attached :photo
      end

      def attach(path, attachment_attributes) # simulate file attachment
        attachment = HyperResource::ActiveStorage::Attachment.new(attachment_attributes)
        Form.current.submission.write(path, attachment.signed_id)
        Form.current.submission.data['contact'] ||= {}
        Form.current.submission.data['contact']['photo'] = attachment
        Form.current.mutate
      end
    end
  end

  context 'mode = input' do

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
                attribute_name: 'photo',
                normalized_input_prefix: 'contact@0',
                type: 'Attachment::HasOne',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                photo: {} # TODO
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display an input file' do
        expect(page).to have_selector('input[type="file"]', visible: false)
      end

      context 'file attached' do
        before(:each) do
          page_exec do
            attach(['contact', 0, 'photo'], {signed_id: "12344321", filename: 'file.txt', content_type: 'application/text'})
          end
        end

        it 'should display file name when file is attached' do
          expect(page).to have_content('file.txt')
        end

        it 'should submit signed_id' do
          expect(
            page_eval do
              Form.current.submission.params.to_n
            end
          ).to eq(
            "contact@0" => {"photo"=>"12344321"}
          )
        end
      end

    end

    context 'record' do
      before(:each) do
        mount do
          Form(record: Contact.new(civility: 'mrs')) do
            Form::Element::Attachment::HasOne(attribute_name: 'photo')
          end
        end
      end

      it 'should display an input file' do
        expect(page).to have_selector('input[type="file"]', visible: false)
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
                attribute_name: 'photo',
                normalized_input_prefix: 'contact@0',
                type: 'Attachment::HasOne',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                id: 1,
                photo: {attachment: {signed_id: 'XXXX', filename: 'photo.png', content_type: 'impage/png'}}
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
        expect(page).to have_selector('.fa-times')
      end
    end

  end

  context 'mode = read_only' do

    context 'dynamic' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'D::Uneek::Contact',
            mode: 'read_only',
            elements: [
              {
                id: 1,
                klass_name: 'Contact',
                root_klass_name: 'Contact',
                attribute_name: 'photo',
                normalized_input_prefix: 'contact@0',
                type: 'Attachment::HasOne',
              },
            ],
            serialized_record_for_input_prefix: {
              'contact@0': {
                photo: {} # TODO
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      context 'file attached' do
        before(:each) do
          @signed_id = '12344321'
          @filename = 'file.txt'
          page_exec do
            attach(['contact', 0, 'photo'], {signed_id: @signed_id, filename: @filename, content_type: 'application/text'})
          end
        end

        xit "should show record's photo" do # can't mock native http requests that comes from browser (it needs a chrome extension like oh-my-mock)
          expect(page).to have_css("img[src=\"/api/files/blobs/#{@signed_id}/#{@filename}\"]")
        end

      end
    end
  end

end


