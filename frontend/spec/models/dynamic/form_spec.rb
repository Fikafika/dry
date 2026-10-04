describe 'Dynamic::Form', type: :system do

  describe '.record_for_element' do
    it 'should retrieve record associated values' do
      page_exec do
        class Nested < HyperResource::Base
        end
        class Record < HyperResource::Base
          has_many :nesteds, class_name: 'Nested'
        end

        $dynamic_form = Dynamic::Form.new(
          id: 1,
          klass_name: 'Record',
          elements: [
            {
              id: 1,
              klass_name: 'Record',
              root_klass_name: 'Record',
              method_names: [],
              attribute_name: 'nesteds',
              normalized_input_prefix: 'record@0',
              mode: 'nested_form',
              type: 'Association::HasMany',
            }, {
              id: 2,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nesteds'],
              normalized_input_prefix: 'record@0.nesteds@0',
              attribute_name: 'attr',
              parent_id: 1,
              type: 'Attribute::String',
            }
          ],
          serialized_record_for_input_prefix: {
            'record@0.nesteds@0': {
              attr: 'A'
            },
            'record@0.nesteds@1': {
              attr: 'B',
            },
          },
        )
        $element = $dynamic_form.elements.first
        $submission = Form::DynamicFormSubmission.new
      end
      expect(
        page_eval do
          $dynamic_form.record_for_element($element, $submission).nesteds.map(&:attributes).to_n
        end
      ).to eq [{'attr' => 'A'}, {'attr' => 'B'}]

    end

    it 'should keep an embedded belongs_to value serialized as a hash (schema default)' do
      page_exec do
        class Nested < HyperResource::Base
        end
        class Record < HyperResource::Base
          belongs_to :nested, class_name: 'Nested'
        end

        $dynamic_form = Dynamic::Form.new(
          id: 1,
          klass_name: 'Record',
          elements: [
            {
              id: 1,
              klass_name: 'Record',
              root_klass_name: 'Record',
              method_names: [],
              attribute_name: 'nested',
              normalized_input_prefix: 'record@0',
              type: 'Association::BelongsTo',
            },
          ],
          serialized_record_for_input_prefix: {
            'record@0': {
              id: nil,
              nested: {
                id: '018c3f81-cefd-7704-a028-b3648cf9df5d',
                name: 'nested 1',
              },
            },
          },
        )
        $element = $dynamic_form.elements.first
        $submission = Form::DynamicFormSubmission.new
      end
      expect(
        page_eval do
          $dynamic_form.record_for_element($element, $submission).nested.attributes.to_n
        end
      ).to eq({'id' => '018c3f81-cefd-7704-a028-b3648cf9df5d', 'name' => 'nested 1'})
    end

    it 'should retrieve record associated values' do
      page_exec do
        class Nested < HyperResource::Base
          has_many :nesteds, class_name: 'Nested'
          belongs_to :nested, class_name: 'Nested'
        end
        class Record < HyperResource::Base
          has_many :nesteds, class_name: 'Nested'
          belongs_to :nested, class_name: 'Nested'
        end

        $dynamic_form = Dynamic::Form.new(
          id: 1,
          klass_name: 'Record',
          elements: [
            {
              id: 1,
              klass_name: 'Record',
              root_klass_name: 'Record',
              method_names: [],
              attribute_name: 'nested',
              normalized_input_prefix: 'record@0',
              mode: 'nested_form',
              type: 'Association::BelongsTo',
            },
            {
            id: 2,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested'],
              attribute_name: 'attr',
              normalized_input_prefix: 'record@0.nested@0',
              parent_id: 1,
              type: 'Attribute::String',
            },
            {
              id: 3,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested'],
              attribute_name: 'nesteds',
              normalized_input_prefix: 'record@0.nested@0',
              mode: 'nested_form',
              parent_id: 1,
              type: 'Association::HasMany',
            },
            {
              id: 4,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested', 'nesteds'],
              attribute_name: 'attr',
              normalized_input_prefix: 'record@0.nested@0.nesteds@0',
              parent_id: 3,
              type: 'Attribute::String',
            },
            {
              id: 5,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested', 'nesteds'],
              attribute_name: 'nested',
              normalized_input_prefix: 'record@0.nested@0.nesteds@0',
              mode: 'nested_form',
              parent_id: 3,
              type: 'Association::BelongsTo',
            },
            {
              id: 6,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested', 'nesteds'],
              attribute_name: 'attr',
              normalized_input_prefix: 'record@0.nested@0.nesteds@0',
              parent_id: 5,
              type: 'Attribute::String',
            },
          ],
          serialized_record_for_input_prefix: {
            'record@0.nested@0': {
              attr: 'A',
            },
            'record@0.nested@0.nesteds@0': {
              attr: 'B',
            },
            'record@0.nested@0.nesteds@0.nested@0': {
              attr: 'C',
            },
          },
        )

        $nested_form1 = $dynamic_form.elements.select{|e| e.mode == 'nested_form'}[0]
        $nested_form2 = $dynamic_form.elements.select{|e| e.mode == 'nested_form'}[1]
        $nested_form3 = $dynamic_form.elements.select{|e| e.mode == 'nested_form'}[2]

        $submission = Form::DynamicFormSubmission.new

        $dynamic_form.elements.each do |e|
          $dynamic_form.record_for_element(e, $submission) # call in same order as rendering to cause a potential bug when string element is before nested form
        end
      end

      expect(
        page_eval do
          $dynamic_form.record_for_element($nested_form1, $submission).nested.attributes.to_n # record.nested@0.attributes
        end
      ).to eq({'attr' => 'A'})

      expect(
        page_eval do
          $dynamic_form.record_for_element($nested_form2, $submission).nesteds.map(&:attributes).to_n # record.nested@0.nesteds.map(&:attributes)
        end
      ).to eq([{'attr' => 'B', 'nested_id' => nil}])

      expect(
        page_eval do
          $dynamic_form.record_for_element($nested_form3, $submission).nested.attributes.to_n # record.nested@0.nesteds@0.nested.attributes
        end
      ).to eq({'attr' => 'C'})
    end

  end

end

