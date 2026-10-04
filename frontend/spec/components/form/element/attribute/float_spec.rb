describe 'Form::Element::Attribute::Float', type: :system do

  before(:each) do
    page_exec do
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
      end
    end
  end

  context 'mode = input' do

    context 'attribute_format = x100_percentage' do
      before(:each) do
        page_exec do
          class Record
            def self.attribute_format(attr)
              'x100_percentage' if attr == 'ratio'
            end
          end
        end
      end

      context 'value loaded from DB' do
        before(:each) do
          mount do
            Form(record: Record.new(ratio: 0.12)) do
              Form::Element::Attribute::Float(attribute_name: 'ratio')
            end
          end
        end

        it 'should display the value shifted x100 in the input' do
          expect(find('input[name="record[ratio]"]').value).to eq '12'
        end

        it 'should keep the raw value in submission params' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'ratio')
          }).to eq 0.12
        end
      end

      context 'user fills input' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::Float(attribute_name: 'ratio')
            end
          end

          find('input[name="record[ratio]"]').set('15')
        end

        it 'should store the value shifted back in submission' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'ratio')
          }).to eq 0.15
        end
      end
    end

    context 'attribute_format = thousands' do
      before(:each) do
        page_exec do
          class Record
            def self.attribute_format(attr)
              'thousands' if attr == 'weight'
            end
          end
        end
      end

      context 'value loaded from DB' do
        before(:each) do
          mount do
            Form(record: Record.new(weight: 1570)) do
              Form::Element::Attribute::Float(attribute_name: 'weight')
            end
          end
        end

        it 'should display the value divided by a thousand in the input' do
          expect(find('input[name="record[weight]"]').value).to eq '1.57'
        end

        it 'should keep the raw value in submission params' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'weight')
          }).to eq 1570
        end
      end

      context 'user fills input' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::Float(attribute_name: 'weight')
            end
          end

          find('input[name="record[weight]"]').set('2.5')
        end

        it 'should store the value shifted back in submission' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'weight')
          }).to eq 2500
        end
      end

      context 'input constraints' do
        before(:each) do
          mount do
            Form(record: Record.new(weight: 1570)) do
              Form::Element::Attribute::Float(attribute_name: 'weight')
            end
          end
        end

        it 'should allow any decimal step' do
          expect(find('input[name="record[weight]"]')[:step]).to eq 'any'
        end
      end

      context 'value with trailing zeros once scaled' do
        before(:each) do
          mount do
            Form(record: Record.new(weight: 10000)) do
              Form::Element::Attribute::Float(attribute_name: 'weight')
            end
          end
        end

        it 'should not display trailing zeros in the input' do
          expect(find('input[name="record[weight]"]').value).to eq '10'
        end
      end

      context 'user types a value ending with a decimal separator' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::Float(attribute_name: 'weight')
            end
          end

          find('input[name="record[weight]"]').send_keys('1', '0', '.')
        end

        it 'should leave the submission empty until the value is complete' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'weight')
          }).to eq ''
        end
      end

      context 'user types a decimal value key by key' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::Float(attribute_name: 'weight')
            end
          end

          find('input[name="record[weight]"]').send_keys('1', '.', '5', '7')
        end

        it 'should keep the decimal separator while typing' do
          expect(find('input[name="record[weight]"]').value).to eq '1.57'
        end

        it 'should store the value shifted back in submission' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'weight')
          }).to eq 1570
        end
      end
    end

    context 'attribute_format = ppm' do
      before(:each) do
        page_exec do
          class Record
            def self.attribute_format(attr)
              'ppm' if attr == 'ratio'
            end
          end
        end
        mount do
          Form(record: Record.new(ratio: 0.0005)) do
            Form::Element::Attribute::Float(attribute_name: 'ratio')
          end
        end
      end

      it 'should display the value multiplied by a million in the input' do
        expect(find('input[name="record[ratio]"]').value).to eq '500'
      end

      it 'should store the value shifted back in submission' do
        find('input[name="record[ratio]"]').set('250')
        expect(page_eval{
          Form.current.submission.params.dig('record', 'ratio')
        }).to eq 0.00025
      end
    end

    context 'no attribute_format' do
      before(:each) do
        mount do
          Form(record: Record.new(ratio: 0.12)) do
            Form::Element::Attribute::Float(attribute_name: 'ratio')
          end
        end
      end

      it 'should display the raw value' do
        expect(find('input[name="record[ratio]"]').value).to eq '0.12'
      end

      it 'should keep the raw value in submission' do
        expect(page_eval{
          Form.current.submission.params.dig('record', 'ratio')
        }).to eq 0.12
      end
    end

  end

  context 'form.mode = edit_in_place' do

    context 'attribute_format = x100_percentage' do
      before(:each) do
        page_exec do
          class Record
            def self.attribute_format(attr)
              'x100_percentage' if attr == 'ratio'
            end
            def self.attribute_format_options(_attr)
              {}
            end
          end
        end
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 1,
                mode: 'edit_in_place',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'ratio',
                normalized_input_prefix: 'record@0',
                type: 'Attribute::Float',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                id: 1,
                ratio: 0.12,
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
        page_exec do
          stub_request(:patch, '/records/1.json').to_return do |request|
            $patch_body = JSON.parse(request.body)
            `document.body.dataset.patchSent = 'true'`
            {
              status: 200,
              body: {
                id: 1,
                ratio: 0.15,
              }.to_json,
            }
          end
        end
      end

      it 'should display the value shifted x100 when editing' do
        find('.form-control').click
        expect(find('input[name="record[ratio]"]').value).to eq '12'
      end

      it 'should submit the raw value to the backend' do
        find('.form-control').click
        find('input[name="record[ratio]"]').set('15')
        page_exec do
          ::Element['input[name="record[ratio]"]'].blur
        end
        expect(page).to have_selector('body[data-patch-sent="true"]', visible: :all)
        expect(page_eval{ $patch_body.dig('record', 'ratio') }).to eq 0.15
      end
    end

  end
end
