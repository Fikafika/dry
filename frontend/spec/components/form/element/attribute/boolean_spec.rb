describe 'Form::Element::Attribute::Boolean', type: :system do
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

    context 'editor = nil' do

      context 'value = nil' do
        context 'optional' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: nil)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr')
              end
            end
          end

          it 'should not be checked' do
            expect(find('input[name="record[attr]"]')).to_not be_checked
          end

          it 'should init submission params to nil' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq ''
          end
        end

        context 'mandatory' do # same as optional
          before(:each) do
            mount do
              Form(record: Record.new(attr: nil)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', requirement: 'mandatory')
              end
            end
          end

          it 'should not be checked' do
            expect(find('input[name="record[attr]"]')).to_not be_checked
          end

          it 'should init submission params to nil' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq ''
          end
        end

        context 'default_value = true' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: nil)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', default_value: true)
              end
            end
          end

          it 'should be checked' do
            expect(find('input[name="record[attr]"]')).to be_checked
          end

          it 'should init submission params to 1' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end
      end

      context 'value = false' do
        context 'optional' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: false)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr')
              end
            end
          end

          it 'should not be checked' do
            expect(find('input[name="record[attr]"]')).to_not be_checked
          end

          it 'should init submission params to 0' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end

        context 'mandatory' do # same as optional
          before(:each) do
            mount do
              Form(record: Record.new(attr: false)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', requirement: 'mandatory')
              end
            end
          end

          it 'should not be checked' do
            expect(find('input[name="record[attr]"]')).to_not be_checked
          end

          it 'should init submission params to 0' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end

        context 'default_value = true' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: false)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', default_value: true)
              end
            end
          end

          it 'should not be checked' do
            expect(find('input[name="record[attr]"]')).to_not be_checked
          end

          it 'should init submission params to 0 (not default_value)' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end
      end

      context 'value = true' do
        context 'optional' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr')
              end
            end
          end

          it 'should be checked' do
            expect(find('input[name="record[attr]"]')).to be_checked
          end

          it 'should init submission params to 0' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end

        context 'mandatory' do # same as optional
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', requirement: 'mandatory')
              end
            end
          end

          it 'should be checked' do
            expect(find('input[name="record[attr]"]')).to be_checked
          end

          it 'should init submission params to 1' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end

        context 'default_value = false' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', default_value: false)
              end
            end
          end

          it 'should be checked' do
            expect(find('input[name="record[attr]"]')).to be_checked
          end

          it 'should init submission params to 1 (not default_value)' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end
      end

      context 'serialized' do
        context 'true (default value)' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', serialized: true)
              end
            end
          end

          it 'should be checked' do
            expect(find('input[name="record[attr]')).to be_checked
          end

          it 'should submission params to 1' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end

          it 'should be unchecked' do
            find('input[id="input-record-attr').click # click in checkbox
            expect(find('input[name="record[attr]')).to_not be_checked
          end

          it 'should submission params to 0' do
            find('input[id="input-record-attr').click
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end

          it 'should be unchecked with click in label' do
            find('[for=input-record-attr]').click # click in label
            expect(find('input[name="record[attr]')).to_not be_checked
          end

          it 'should submission params to 0 click in label' do
            find('[for=input-record-attr]').click
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end

        context 'false : true / false value' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(attribute_name: 'attr', serialized: false)
              end
            end
          end

          it 'should initialize submission params to true' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq "true"
          end

          it 'should be checked' do
            expect(find('input[name="record[attr]')).to be_checked
          end

          it 'should be unchecked' do
            find('input[id="input-record-attr').click
            expect(find('input[name="record[attr]')).to_not be_checked
          end

          it 'should submission params to false' do
            find('input[id="input-record-attr').click
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq "false"
          end

          it 'should submission params to true with double click' do
            find('input[id="input-record-attr').click
            find('input[id="input-record-attr').click
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq "true"
          end

          it 'should be unchecked with click in label' do
            find('[for=input-record-attr]').click
            expect(find('input[name="record[attr]')).to_not be_checked
          end

          it 'should submission params to false click in label' do
            find('[for=input-record-attr]').click
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq 'false'
          end
        end
      end
    end

    context 'editor = switch' do

      context 'value = nil' do
        context 'optional' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: nil)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr')
              end
            end
          end

          it 'should be at middle' do
            expect(find('input[type="range"]').value).to eq '0.5'
          end

          it 'should init submission params to nil' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq ''
          end
        end

        context 'mandatory' do  # different from optional
          before(:each) do
            mount do
              Form(record: Record.new(attr: nil)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', requirement: 'mandatory')
              end
            end
          end

          it 'should be at left' do
            expect(find('input[type="range"]').value).to eq '0'
          end

          it 'should init submission params to nil' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end

        context 'default_value = true' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: nil)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', default_value: true)
              end
            end
          end

          it 'should be at right' do
            expect(find('input[type="range"]').value).to eq '1'
          end

          it 'should init submission params to 1' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end
      end

      context 'value = true' do
        context 'optional' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr')
              end
            end
          end

          it 'should be at right' do
            expect(find('input[type="range"]').value).to eq '1'
          end

          it 'should init submission params' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end

        context 'mandatory' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', requirement: 'mandatory')
              end
            end
          end

          it 'should be at right' do
            expect(find('input[type="range"]').value).to eq '1'
          end

          it 'should init submission params' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end

        context 'default_value = false' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: true)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', default_value: false)
              end
            end
          end

          it 'should be at right' do
            expect(find('input[type="range"]').value).to eq '1'
          end

          it 'should init submission params to 1 (_value)' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '1'
          end
        end
      end

      context 'value = false' do
        context 'optional' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: false)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr')
              end
            end
          end

          it 'should be at left' do
            expect(find('input[type="range"]').value).to eq '0'
          end

          it 'should init submission params' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end

        context 'mandatory' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: false)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', requirement: 'mandatory')
              end
            end
          end

          it 'should be at left' do
            expect(find('input[type="range"]').value).to eq '0'
          end

          it 'should init submission params' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end

        context 'default_value = true' do
          before(:each) do
            mount do
              Form(record: Record.new(attr: false)) do
                Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', default_value: true)
              end
            end
          end

          it 'should be at left' do
            expect(find('input[type="range"]').value).to eq '0'
          end

          it 'should init submission params to 0 (not default_value)' do
            expect(page_eval{
              Form.current.submission.params.dig('record', 'attr').to_s
            }).to eq '0'
          end
        end
      end

      context 'serialized' do
        context 'true (default value)' do
          context "value = true" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: true)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: true)
                end
              end
            end

            it 'should be at right' do
              expect(find('input[type="range"]').value).to eq '1'
            end

            it 'should submission params to 1' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq '1'
            end
          end

          context "value = false" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: false)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: true)
                end
              end
            end

            it 'should be at left' do
              expect(find('input[type="range"]').value).to eq '0'
            end

            it 'should submission params to 0' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq '0'
            end
          end

          context "value = nil" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: nil)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: true)
                end
              end
            end

            it 'should be at middle' do
              expect(find('input[type="range"]').value).to eq '0.5'
            end

            it 'should submission params to nil' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq ''
            end
          end
        end

        context 'false : true / false value' do
          context "value = true" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: true)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: false)
                end
              end
            end

            it 'should be at right' do
              expect(find('input[type="range"]').value).to eq '1'
            end

            it 'should initialize submission params to true' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq "true"
            end
          end

          context "value = false" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: false)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: false)
                end
              end
            end

            it 'should be at left' do
              expect(find('input[type="range"]').value).to eq '0'
            end

            it 'should initialize submission params to false' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq "false"
            end
          end

          context "value = nil" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: nil)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: false)
                end
              end
            end

            it 'should be at middle' do
              expect(find('input[type="range"]').value).to eq '0.5'
            end

            it 'should submission params to nil' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq ''
            end
          end
        end
        context 'mandatory' do
          context "value = nil" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: nil)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: false, requirement: 'mandatory')
                end
              end
            end

            it 'should be at left' do
              expect(find('input[type="range"]').value).to eq '0'
            end

            it 'should submission params to left' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq 'false'
            end
          end

          context "value = false" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: false)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: false, requirement: 'mandatory')
                end
              end
            end

            it 'should be at left' do
              expect(find('input[type="range"]').value).to eq '0'
            end

            it 'should submission params to false' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq 'false'
            end
          end

          context "value = true" do
            before(:each) do
              mount do
                Form(record: Record.new(attr: true)) do
                  Form::Element::Attribute::Boolean(editor: 'switch', attribute_name: 'attr', serialized: false, requirement: 'mandatory')
                end
              end
            end

            it 'should be at right' do
              expect(find('input[type="range"]').value).to eq '1'
            end

            it 'should submission params to true' do
              expect(page_eval{
                Form.current.submission.params.dig('record', 'attr').to_s
              }).to eq 'true'
            end
          end
        end
      end
    end

  end
end
