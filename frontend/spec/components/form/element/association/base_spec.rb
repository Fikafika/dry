describe 'Form::Element::Association::Base', type: :system do
  before(:each) do
    page_exec do
      class Nested < HyperResource::Base
        def self.api_path
          '/nesteds'
        end
        def self.icon
          'square'
        end
        def self.name_attribute
          'name'
        end
        def self.photo_attachment
          'photo'
        end
        has_one_attached :photo
        belongs_to :nested, class_name: 'Nested'
        has_many :nesteds, class_name: 'Nested'
      end
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
        belongs_to :nested, class_name: 'Nested'
        has_many :nesteds, class_name: 'Nested'
      end
    end
  end

  describe 'render', type: :system do
    context 'mix of belongs_to and has_many' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
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
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should have correct values in input' do
        expect(find('input[name="record.nested@0[attr]"]').value).to eq('A')
        expect(find('input[name="record.nested@0.nesteds@0[attr]"]').value).to eq('B')
        expect(find('input[name="record.nested@0.nesteds@0.nested@0[attr]"]').value).to eq('C')
      end
    end
  end

  describe 'for_each_child', type: :system do
    context 'has_many association inside a condition wrapper' do
      before(:each) do
        mount do
          record = Record.new(
            nesteds: [
              Nested.new(
                id: 'aaa',
                nesteds: [Nested.new(attr: 'deep')],
              )
            ]
          )
          Form(record: record) do
            Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
              Form::Element::Layout::Condition(id: ['aaa']) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
          end
        end
      end

      it 'includes nested association found through condition wrapper in submission params' do
        expect(
          page_eval { Form.current.submission.params.to_n }
        ).to eq({
          'record' => {
            'nesteds_attributes' => [
              {
                'nesteds_attributes' => [{ 'attr' => 'deep' }],
              }
            ]
          }
        })
      end
    end

    context 'belongs_to association inside a condition wrapper' do
      before(:each) do
        mount do
          record = Record.new(
            nesteds: [
              Nested.new(
                id: 'aaa',
                nested: Nested.new(id: 'bbb', attr: 'child'),
              )
            ]
          )
          Form(record: record) do
            Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
              Form::Element::Layout::Condition(id: ['aaa']) do
                Form::Element::Association::BelongsTo(attribute_name: 'nested', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
          end
        end
      end

      it 'includes belongs_to found through condition wrapper in submission params' do
        expect(
          page_eval { Form.current.submission.params.to_n }
        ).to eq({
          "record" => {
            "nesteds_attributes" => [
              {
                "nested_attributes" => [
                  {
                    "attr"=>"child",
                    "id"=>"bbb",
                  }
                ]
              }
            ]
          }
        })
      end
    end

    context 'two sibling conditions with different attributes' do
      before(:each) do
        mount do
          record = Record.new(
            nesteds: [
              Nested.new(
                id: 'aa345a',
                nesteds: [Nested.new(attr: 'r')]
              ),
              Nested.new(
                id: 'bb5672',
                nesteds: [
                  Nested.new(attr_x: 'X', attr_y: 'y', attr_w: 'w', attr_z: 'B'),
                  Nested.new(attr_x: 'X', attr_y: 'f', attr_w: 'g', attr_z: 'Z'),
                  Nested.new(attr_x: 'A', attr_y: nil, attr_w: 't', attr_z: 'Z'),
                  Nested.new(attr_x: 'A', attr_y: nil, attr_w: nil, attr_z: 'B'),
                ]
              )
            ]
          )
          Form(record: record) do
            Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
              Form::Element::Layout::Condition(id: ['aa345a']) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
              Form::Element::Layout::Condition(id: ['bb5672']) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr_x')
                  Form::Element::Attribute::String(attribute_name: 'attr_y')
                  Form::Element::Attribute::String(attribute_name: 'attr_w')
                end
              end
            end
          end
        end
      end

      it 'includes attributes from both conditions in submission params' do
        expect(
          page_eval { Form.current.submission.params.to_n }
        ).to eq({
          'record' => {
            'nesteds_attributes' => [
              {
                'nesteds_attributes' => [
                  { 'attr' => 'r' }
                ]
              },
              {
                'nesteds_attributes' => [
                  { 'attr_w' => 'w', 'attr_x' => 'X', 'attr_y' => 'y' },
                  { 'attr_w' => 'g', 'attr_x' => 'X', 'attr_y' => 'f' },
                  { 'attr_w' => 't', 'attr_x' => 'A', 'attr_y' => nil },
                  { 'attr_w' => nil, 'attr_x' => 'A', 'attr_y' => nil }
                ]
              }
            ]
          }
        })
      end
    end

    context 'condition wrapping attributes with a nested condition underneath' do
      before(:each) do
        mount do
            record = Record.new(
              nesteds: [
                Nested.new(
                  id: 'eftz342',
                  nesteds: [Nested.new(attr: 'r')]
                ),
                Nested.new(
                  id: 'aa345a',
                  attr: 'elu',
                  nesteds: [
                    Nested.new(
                      id: 'bb5672',
                      attr_x: 'X',
                      attr_y: 'y',
                      nesteds: [
                        Nested.new(id: 'tnu652t', attr_a: 'X', attr_b: 'f'),
                        Nested.new(attr_a: 'A', attr_b: nil),
                        Nested.new(attr_a: 'C', attr_b: nil),
                        Nested.new(
                          id: 'f553ra',
                          attr_a: 'A',
                          attr_b: 'B',
                          nesteds: [
                            Nested.new(
                              id: 'rtd345z',
                              type: 'r',
                              nesteds: [
                                Nested.new(id: 'ert3214', attr_s: 'r')
                              ]
                            )
                          ]
                        ),
                      ]
                    )
                  ]
                )
              ]
            )
            Form(record: record) do
              Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                Form::Element::Layout::Condition(id: ['aa345a']) do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                  Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                    Form::Element::Layout::Condition(id: ['bb5672']) do
                      Form::Element::Attribute::String(attribute_name: 'attr_x')
                      Form::Element::Attribute::String(attribute_name: 'attr_y')
                      Form::Element::Attribute::String(attribute_name: 'attr_z')
                      Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                        Form::Element::Layout::Condition(id: ['f553ra']) do
                          Form::Element::Attribute::String(attribute_name: 'attr_a')
                          Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                            Form::Element::Layout::Condition(id: ['rtd345z']) do
                              Form::Element::Attribute::String(attribute_name: 'type')
                              Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                                Form::Element::Layout::Condition(id: ['ert3214']) do
                                  Form::Element::Attribute::String(attribute_name: 'attr_s')
                                end
                              end
                            end
                          end
                        end
                        Form::Element::Layout::Condition(id: ['tnu652t']) do
                          Form::Element::Attribute::String(attribute_name: 'attr_b')
                        end
                      end
                    end
                  end
                end
              end
            end
        end
      end

      it 'includes attributes from both conditions in submission params' do
        expect(
          page_eval { Form.current.submission.params.to_n }
        ).to eq({
          'record' => {
            'nesteds_attributes' => [
              {
                'id'    => 'aa345a',
                'attr'  => 'elu',
                'nesteds_attributes' => [
                  {
                    'id'     => 'bb5672',
                    'attr_x' => 'X',
                    'attr_y' => 'y',
                    'attr_z' => nil,
                    'nesteds_attributes' => [
                      {},
                      {},
                      {
                        'id'     => 'f553ra',
                        'attr_a' => 'A',
                        'nesteds_attributes' => [
                          {
                            'id'   => 'rtd345z',
                            'type' => 'r',
                            'nesteds_attributes' => [
                              {
                                'id'     => 'ert3214',
                                'attr_s' => 'r'
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'id'     => 'tnu652t',
                        'attr_b' => 'f'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        })
      end
    end
  end
end