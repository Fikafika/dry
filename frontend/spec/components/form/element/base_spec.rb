describe 'Form::Element::Attribute::Base', type: :system do

  context 'dynamic_form' do

    context 'with element with input_prefix with several dots' do
      before(:each) do
        page_exec do
          class Record < HyperResource::Base
            belongs_to :record, class_name: 'Record'
            attr_accessor :attr
          end
        end

        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'input',
            elements: [
              {
                id: 1,
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: ['record', 'record'],
                attribute_name: 'attr',
                normalized_input_prefix: 'record@0.record@0.record@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {},
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end

        expect(page).to have_css('input[name="record.record@0.record@0[attr]"]')
      end

      it 'should init submission params properly' do
        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq(
          {
            'record@0.record@0.record@0' => { 'attr' => nil },
          }
        )
      end
    end

    context 'inside a nested form' do
      before(:each) do
        page_exec do
          class Record < HyperResource::Base
            belongs_to :record, class_name: 'Record'
            attr_accessor :attr
          end
        end

        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'input',
            elements: [
              {
                id: 1,
                mode: 'nested_form',
                klass_name: 'Record',
                root_klass_name: 'Record',
                attribute_name: 'record',
                normalized_input_prefix: 'record@0.record@0',
                type: 'Association::BelongsTo',
              },
              {
                id: 2,
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: ['record', 'record'],
                parent_id: 1,
                attribute_name: 'attr',
                normalized_input_prefix: 'record@0.record@0.record@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {},
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end

        expect(page).to have_css('input[name="record.record@0.record@0[attr]"]')
      end

      it 'should init submission params properly' do
        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq(
          {
            'record@0.record@0.record@0' => { 'attr' => nil },
          }
        )
      end
    end

  end

end
