describe 'Form::Element::Attribute::Hash', type: :system do
  before(:each) do
    page_exec do
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
      end
    end
  end

  context 'mode = nested_form' do

    context '' do
      before(:each) do
        mount do
          record = Record.new(a: {b: 1})
          Form(record: record) do
            Form::Element::Attribute::Hash(attribute_name: 'a', mode: 'nested_form') do
              Form::Element::Attribute::Integer(attribute_name: 'b')
            end
          end
        end
      end

      it 'should have attribute value' do
        expect(find('input[name="record[a][b]"]').value).to eq '1'
      end

      it 'should init submission params' do
        expect(page_eval{
          Form.current.submission.params.dig('record', 'a', 'b').to_s
        }).to eq '1'
      end
    end

    context 'nested nested' do
      before(:each) do
        mount do
          record = Record.new(a: {b: {c: 1}})
          Form(record: record) do
            Form::Element::Attribute::Hash(attribute_name: 'a', mode: 'nested_form') do
              Form::Element::Attribute::Hash(attribute_name: 'b', mode: 'nested_form') do
                Form::Element::Attribute::Integer(attribute_name: 'c')
              end
            end
          end
        end
      end

      it 'should have attribute value' do
        expect(find('input[name="record[a][b][c]"]').value).to eq '1'
      end

      it 'should init submission params' do
        expect(page_eval{
          Form.current.submission.params.dig('record', 'a', 'b', 'c').to_s
        }).to eq '1'
      end

      it 'user change value should change submission' do
        find('input[name="record[a][b][c]"]').set('2')
        expect(page_eval{
          Form.current.submission.params.dig('record', 'a', 'b', 'c').to_s
        }).to eq '2'
      end
    end

    context 'nested with same attribute_name' do
      before(:each) do
        def mount_form
          mount do
            record = Record.new($attrs)
            Form(record: record) do
              Form::Element::Attribute::Hash(attribute_name: 'b', mode: 'nested_form') do
                Form::Element::Attribute::Integer(attribute_name: 'a')
              end
            end
          end
        end
      end

      it 'should have attribute value' do
        page_eval do
          $attrs = {a: 1, b: { a: 2}}
        end
        mount_form
        expect(find('input[name="record[b][a]"]').value).to eq '2'
      end

      it 'should have attribute value when nested attribute is nil' do
        page_eval do
          $attrs = {a: 1, b: { a: nil}}
        end
        mount_form
        expect(find('input[name="record[b][a]"]').value).to eq ''
      end

      it 'should have attribute value when nested attribute is missing' do
        page_eval do
          $attrs = {a: 1, b: {}}
        end
        mount_form
        expect(find('input[name="record[b][a]"]').value).to eq ''
      end

    end

  end
end
