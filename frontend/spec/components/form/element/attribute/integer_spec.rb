describe 'Form::Element::Attribute::Integer', type: :system do

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

    context 'attribute_format = thousands' do
      before(:each) do
        page_exec do
          class Record
            def self.attribute_format(attr)
              'thousands' if attr == 'quantity'
            end
          end
        end
      end

      context 'value loaded from DB' do
        before(:each) do
          mount do
            Form(record: Record.new(quantity: 1570)) do
              Form::Element::Attribute::Integer(attribute_name: 'quantity')
            end
          end
        end

        it 'should display the value rounded to the unit in the input' do
          expect(find('input[name="record[quantity]"]').value).to eq '2'
        end

        it 'should keep the raw value in submission params' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'quantity')
          }).to eq 1570
        end
      end

      context 'user fills input' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::Integer(attribute_name: 'quantity')
            end
          end

          find('input[name="record[quantity]"]').set('2')
        end

        it 'should store the value shifted back in submission' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'quantity')
          }).to eq 2000
        end
      end

      context 'user fills input with a decimal value' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::Integer(attribute_name: 'quantity')
            end
          end

          find('input[name="record[quantity]"]').set('1.5555')
        end

        it 'should round the stored value to an integer' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'quantity')
          }).to eq 1556
        end

        it 'should keep what the user typed in the input' do
          expect(find('input[name="record[quantity]"]').value).to eq '1.5555'
        end
      end

      context 'input constraints' do
        before(:each) do
          mount do
            Form(record: Record.new(quantity: 1570)) do
              Form::Element::Attribute::Integer(attribute_name: 'quantity')
            end
          end
        end

        it 'should only allow integer steps' do
          expect(find('input[name="record[quantity]"]')[:step]).to eq '1'
        end
      end
    end

    context 'no attribute_format' do
      before(:each) do
        page_exec do
          class Record
            def self.attribute_format(attr)
              nil
            end
          end
        end
        mount do
          Form(record: Record.new(quantity: 1570)) do
            Form::Element::Attribute::Integer(attribute_name: 'quantity')
          end
        end
      end

      it 'should display the raw value' do
        expect(find('input[name="record[quantity]"]').value).to eq '1570'
      end

      it 'should keep the raw value in submission' do
        expect(page_eval{
          Form.current.submission.params.dig('record', 'quantity')
        }).to eq 1570
      end
    end

  end
end
