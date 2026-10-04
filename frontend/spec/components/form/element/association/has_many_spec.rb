describe 'Form::Element::Association::HasMany', type: :system do
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
      end
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
        has_many :nesteds, class_name: 'Nested'
      end
    end
  end

  context 'form.mode = input' do

    context 'element.mode = default' do

      context 'editor = select2' do

        context 'dynamic_form' do

          context 'empty' do
            before(:each) do
              mount do
                dynamic_form = Dynamic::Form.new(
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                    },
                  ],
                  serialized_record_for_input_prefix: {
                    'record@0': {
                      'id': nil,
                    },
                  },
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
              page_exec do
                stub_request(:get, "/nesteds.json?owner_klass_name=Record&association_name=nesteds&term=&select2=true").to_return do |request|
                  {
                    status: 200,
                    body: {
                      results: [{
                        id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        text: 'nested 1',
                        record: {
                          id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                          name: 'nested 1',
                        },
                      }, {
                        id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        text: 'nested 2',
                        record: {
                          id: '2caf771d-7a92-40bb-908c-3c835e054367',
                          name: 'nested 2',
                        },
                      }]
                    }.to_json,
                  }
                end
                stub_request(:post, /\/submit\.json/).to_return do |request|
                  {
                    status: 200,
                    body: {
                      # TODO
                    }.to_json,
                  }
                end
              end
            end

            it 'click in input should open a autocomplete' do
              find('input').click
              expect(page).to have_css('.ts-wrapper .option')
              expect(page).to have_content('nested 1')
              expect(page).to have_content('nested 2')
            end

            context 'click on item' do
              before(:each) do
                find('input').click # open autocomplete
                find('.ts-dropdown  .option', text: 'nested 1').click # click on item
              end

              it 'should show a "tag" in the input' do
                find('.ts-control .item', text: 'nested 1', count: 1)
              end

              it 'should write in submission' do
                expect(
                  page_eval do
                    Form.current.submission.params.to_n
                  end
                ).to eq(
                  {
                    'record@0.nesteds@0' => { 'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b' },
                  }
                )
              end
            end

            it 'reset should remove previously selected items' do
              find('input').click
              find('.ts-dropdown  .option', text: 'nested 1').click
              expect(page).to have_css('.ts-control .item', text: 'nested 1')
              page_exec do
                Form.current.reset
              end
              expect(page).to_not have_css('.ts-control .item', text: 'nested 1')
            end

            it 'should remove previously selected items on click in x' do
              find('input').click
              find('.ts-dropdown  .option', text: 'nested 1').click

              expect(page).to have_css('.ts-control .item', text: 'nested 1')

              find('.ts-control .item .remove').click

              expect(page).to_not have_css('.ts-control .item', text: 'nested 1')

              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq(
                {
                  'record@0.nesteds@0' => { 'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b', '_destroy' => 1 },
                }
              )
            end

            context 'autocomplete_filters' do

              context 'ancetors autocomplete_filters' do
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
                      has_many :nesteds, class_name: 'Nested', inverse_of: :nested_owner
                      belongs_to :nested, class_name: 'Nested'
                    end
                    class Record < HyperResource::Base
                      def self.api_path
                        '/records'
                      end
                      has_many :nesteds, class_name: 'Nested', inverse_of: :owner
                    end

                    stub_request(:get, /\/nesteds\.json/).to_return do |request|
                      {
                        status: 200,
                        body: {
                          results: [{
                            id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                            text: 'nested 1',
                          }, {
                            id: '2caf771d-7a92-40bb-908c-3c835e054367',
                            text: 'nested 2',
                          }]
                        }.to_json,
                      }
                    end
                    stub_request(:get, /\/nesteds\/17ad7795e-9899-47a9-a38f-6c1ead61991b\.json/).to_return do |request|
                      {
                        status: 200,
                        body: {
                          id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                          name: 'nested 1',
                          attr: 'A',
                          nesteds: [{
                            id: 'b5d90084-8313-4447-9fd7-f0e3716292d9',
                            name: 'nested 1 nesteds 1',
                            attr: 'AA',
                          }],
                          nested: {
                            id: '76b0f801-4d38-4333-891b-1c90dc6e1e68',
                            name: 'nested 1 nested',
                          },
                        }.to_json,
                      }
                    end
                    stub_request(:get, /\/nesteds\/2caf771d-7a92-40bb-908c-3c835e054367\.json/).to_return do |request|
                      {
                        status: 200,
                        body: {
                          id: '2caf771d-7a92-40bb-908c-3c835e054367',
                          name: 'nested 2',
                          attr: 'B',
                          nesteds: [{
                            id: '6a3d8848-1fea-432d-906c-2f14308e1710',
                            name: 'nested 2 nesteds 1',
                            attr: nil,
                          }],
                          nested: nil,
                        }.to_json,
                      }
                    end
                  end

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
                          attribute_name: 'nesteds',
                          normalized_input_prefix: 'record@0',
                          mode: 'nested_form',
                          min: 1,
                          type: 'Association::HasMany',
                          autocomplete_filters: {attr: {contains: {variable: 'attr'}}},
                        }, {
                          id: 2,
                          klass_name: 'Nested',
                          root_klass_name: 'Record',
                          method_names: ['nesteds'],
                          normalized_input_prefix: 'record@0.nesteds@0',
                          attribute_name: 'nesteds',
                          mode: 'nested_form',
                          parent_id: 1,
                          min: 1,
                          type: 'Association::HasMany',
                          autocomplete_filters: {name: {contains: {variable: 'name'}}},
                        }, {
                          id: 3,
                          klass_name: 'Nested',
                          root_klass_name: 'Record',
                          method_names: ['nesteds', 'nesteds'],
                          normalized_input_prefix: 'record@0.nesteds@0.nesteds@0',
                          attribute_name: 'nesteds',
                          mode: nil,
                          parent_id: 2,
                          type: 'Association::HasMany',
                        },
                      ],
                    )
                    dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                    Form(dynamic_form: dynamic_form)
                  end
                end

                it 'should combine autocomplete filters of the ancestors' do
                  find('input').click
                  sleep 0.1 # Necessary for the calculation time
                  request_url_params = page_eval('WebMock::RequestRegistry.instance.to_s').split(' ')[1]

                  expect(request_url_params).to eq('/nesteds.json?filters=(and%3A!((nested_owner.name%3A(contains%3A(variable%3Aname)))%2C(nested_owner.nested_owner.attr%3A(contains%3A(variable%3Aattr)))))&owner_klass_name=Nested&association_name=nesteds&term=&select2=true&variables%5Bname%5D=&variables%5Battr%5D=')
                end
              end

            end

          end

          context 'not empty' do
            before(:each) do
              mount do
                dynamic_form = Dynamic::Form.new(
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                    },
                  ],
                  serialized_record_for_input_prefix: {
                    'record@0': { 'id': nil },
                    'record@0.nesteds@0': {id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', name: 'nested 1'}
                  },
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
              page_exec do
                stub_request(:get, "/nesteds.json?owner_klass_name=Record&association_name=nesteds&term=&select2=true").to_return do |request|
                  {
                    status: 200,
                    body: {
                      results: [{
                        id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        text: 'nested 1',
                        record: {
                          id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                          name: 'nested 1',
                        },
                      }, {
                        id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        text: 'nested 2',
                        record: {
                          id: '2caf771d-7a92-40bb-908c-3c835e054367',
                          name: 'nested 2',
                        },
                      }]
                    }.to_json,
                  }
                end
              end
            end

            it 'should have select2 items' do
              expect(page).to have_css('.ts-control .item', text: 'nested 1')
            end

            it 'should initialize submission properly' do
              expect(
                page_eval do
                  Form.current.submission.params == {
                    'record@0.nesteds@0' => { 'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b' },
                  }
                end
              ).to eq true
            end

            it 'reset should remove previously selected items' do
              expect(page).to have_css('.ts-control .item', text: 'nested 1')
              expect(page).to_not have_css('.ts-control .item', text: 'nested 2')

              find('input').click
              find('.ts-dropdown  .option', text: 'nested 2').click
              expect(page).to have_css('.ts-control .item', text: 'nested 2')
              page_exec do
                Form.current.reset
              end

              expect(page).to have_css('.ts-control .item', text: 'nested 1')
              expect(page).to_not have_css('.ts-control .item', text: 'nested 2')
            end

          end

        end

        context 'record' do

          context 'not empty' do

            context 'with association name' do
              before(:each) do
                mount do
                  Form(record: Record.new(nesteds: [Nested.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991', name: 'nested 1')])) do
                    Form::Element::Association::HasMany(
                      attribute_name: 'nesteds',
                      editor: 'select2'
                    )
                  end
                end
              end

              it 'should have select2 items' do
                expect(page).to have_css('.ts-control .item', text: 'nested 1')
              end

            end
          end

          context 'attribute_name that ends with _ids' do
            before(:each) do
              mount do
                Form(record: Record.new(nesteds: [Nested.new(id: '64a9345b-d0e1-42e4-bfa5-0b58506ac56f', name: 'nested 1')])) do
                  Form::Element::Association::HasMany(
                    attribute_name: 'nested_ids',
                    editor: 'select2'
                  )
                end
              end
            end

            it 'should have select2 items' do
              expect(page).to have_css('.ts-control .item', text: 'nested 1')
            end
          end


          context 'component with a form that reload after submit' do
            before(:each) do
              page_exec do
                class ComponentWithForm < HyperComponent
                  before_mount do
                    @record = Record.new
                  end
                  render do
                    Form(record: @record) do
                      Form::Element::Association::HasMany(
                        attribute_name: 'nesteds',
                        editor: 'select2'
                      )
                    end.on(:success) do |response|
                      puts response[:body].inspect
                      mutate @record = Record.new(response[:body])
                    end
                  end
                end
              end
              mount do
                ComponentWithForm()
              end
              page_exec do
                stub_request(:get, "/nesteds.json?owner_klass_name=Record&association_name=nesteds&term=&select2=true").to_return do |request|
                  {
                    status: 200,
                    body: {
                      results: [{
                        id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        text: 'nested 1',
                        record: {
                          id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                          name: 'nested 1',
                        },
                      }, {
                        id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        text: 'nested 2',
                        record: {
                          id: '2caf771d-7a92-40bb-908c-3c835e054367',
                          name: 'nested 2',
                        },
                      }]
                    }.to_json,
                  }
                end
                stub_request(:post, /\/submit\.json/).to_return do |request|
                  {
                    status: 200,
                    body: {
                      id: '71ccbb36-823f-4e7e-a1f4-f5c0cc3a0fd7',
                      type: 'Record',
                      nesteds: [{
                        id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        name: 'nested 1',
                      }]
                    }.to_json,
                  }
                end
              end
            end

            it 'click in input should open a autocomplete' do
              find('input').click
              expect(page).to have_css('.ts-dropdown .option')
              expect(page).to have_content('nested 1')
              expect(page).to have_content('nested 2')
            end

            context 'click on item' do
              before(:each) do
                find('input').click # open autocomplete
                find('.ts-dropdown  .option', text: 'nested 1').click # click on item
              end

              it 'should show a "tag" in the input' do
                find('.ts-control .item', text: 'nested 1', count: 1)
              end

              it 'should write in submission' do
                expect(
                  page_eval do
                    Form.current.submission.params.to_n
                  end
                ).to eq(
                  {"record" => {"nesteds_attributes"=>[{"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b"}]}}
                )
              end

              it 'submit should keep selected values after record is reloaded' do
                page_exec do
                  Form.current.submit
                end
                find('.ts-control .item', text: 'nested 1', count: 1)
              end

            end

          end

        end

      end

      context 'editor = checkbox' do
        context 'dynamic_form' do
          context 'without possible values' do
            before(:each) do
              page_exec do
                stub_request(:get, '/nesteds.json?order%5Bname%5D=asc').to_return do |request|
                  {
                    status: 200,
                    body: [
                      {
                        id: '018c3f81-cefd-7704-a028-b3648cf9df5d',
                        name: 'nested 1',
                      }, {
                        id: '018c3f82-2c82-7f1d-afba-e3397decb7b2',
                        name: 'nested 2'
                      }
                    ].to_json,
                  }
                end
              end
              mount do
                dynamic_form = Dynamic::Form.new(
                  id: '018c3f80-af74-7810-8906-e394cbc90155',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: '018c3f81-6ac9-7361-951a-f6cb8c8e3271',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      editor: 'checkbox',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                    },
                  ],
                  serialized_record_for_input_prefix: {
                    'record@0': {
                      'id': nil,
                    },
                  },
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should display checkbox' do
              expect(page).to have_css('input[type="checkbox"]', count: 2)
              expect(page).to have_content('nested 1')
              expect(page).to have_content('nested 2')
            end
          end

          context 'with possible values' do
            before(:each) do
              page_exec do
                stub_request(:get, '/nesteds.json?order%5Bname%5D=asc').to_return do |request|
                  {
                    status: 200,
                    body: [{}]
                  }
                end
              end
              mount do
                dynamic_form = Dynamic::Form.new(
                  id: '018c44ad-0560-7036-b067-9d4efc03476f',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: '018c44ad-3b9e-78cc-991e-6c15fdd6263d',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      editor: 'checkbox',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                      possible_values: [
                        {
                        value_record: {
                          id: 'f0e19422-c637-460b-aa49-b1819d9f300d',
                          type: 'Nested',
                          name: 'value 1',
                        },
                        translations: [{
                          text: 'val 1',
                          locale: 'fr',
                        }],
                        position: 0,
                      },
                      {
                        value_record: {
                          id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                          type: 'Nested',
                          name: 'value 2',
                        },
                        translations: [{
                          text: 'val 2',
                          locale: 'fr',
                        }],
                        position: 1,
                      },
                      ]
                    },
                  ],
                  serialized_record_for_input_prefix: {
                    'record@0': {
                      'id': nil,
                    },
                  },
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should display checkbox of possible values' do
              expect(page).to have_css('input[type="checkbox"]', count: 2)
              expect(page).to have_content('val 1')
              expect(page).to have_content('val 2')
            end

            it 'should send only the selected record as a submission params' do
              find_all('input[type="checkbox"').first.click

              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq({"record@0.nesteds@0" => {"id" => "f0e19422-c637-460b-aa49-b1819d9f300d"}})
            end
          end

          context 'with default values' do
            before(:each) do
              page_exec do
                stub_request(:get, '/nesteds.json?order%5Bname%5D=asc').to_return do |request|
                  {
                    status: 200,
                    body: [
                      {
                        id: 'f0e19422-c637-460b-aa49-b1819d9f300d',
                        type: 'Nested',
                        name: 'value 1',
                      },
                      {
                        id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                        type: 'Nested',
                        name: 'value 2',
                      }
                    ]
                  }
                end
              end
              mount do
                dynamic_form = Dynamic::Form.new(
                  id: '018c44ad-0560-7036-b067-9d4efc03476f',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: '018c44ad-3b9e-78cc-991e-6c15fdd6263d',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      editor: 'checkbox',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                      default_value_records: [
                        {
                          id: 'f0e19422-c637-460b-aa49-b1819d9f300d',
                          type: 'Nested',
                          name: 'value 1',
                        },
                        {
                          id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                          type: 'Nested',
                          name: 'value 2',
                        },
                      ]
                    },
                  ],
                  serialized_record_for_input_prefix: {
                    'record@0': {
                      'id': nil,
                    },
                  },
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should render default checked values' do
              expect(page).to have_css('input[type="checkbox"][checked]', count: 2)
              expect(page).to have_content('value 1')
              expect(page).to have_content('value 2')
            end

            it 'should send only the selected record as a submission params' do
              expect(page).to have_css('input[type="checkbox"][checked]', count: 2)
              find_all('input[type="checkbox"').first.click

              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq({
                "record@0.nesteds@0" => {"id" => "f0e19422-c637-460b-aa49-b1819d9f300d", "_destroy" => 1},
                "record@0.nesteds@1" => {"id" => "f0e19422-c637-460b-aa49-b1819d9f300e"}
              })
            end
          end

          context 'several same elements with different possible values' do # corner case used by enpc
            before(:each) do

              mount do
                dynamic_form = Dynamic::Form.new(
                  id: '018c44ad-0560-7036-b067-9d4efc03476f',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: '018c44ad-3b9e-78cc-991e-6c15fdd6263d',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      editor: 'checkbox',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                      possible_values: [{
                        value_record: {
                          id: '6b56763c-cdb4-483e-bd3e-cf1cd65e129c',
                          type: 'Nested',
                          name: 'A',
                        },
                        position: 0,
                      },
                      {
                        value_record: {
                          id: '2b14fee9-6aca-474e-baea-25ffd0ad9d3b',
                          type: 'Nested',
                          name: 'B',
                        },
                        position: 1,
                      },
                      ]
                    },
                    {
                      id: '12ecba3b-042d-4daa-a0ba-ac44acc33a26',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      editor: 'checkbox',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                      possible_values: [{
                        value_record: {
                          id: '722fcc27-d3b7-45ec-92ce-b36e3234ce27',
                          type: 'Nested',
                          name: 'C',
                        },
                        position: 0,
                      },
                      {
                        value_record: {
                          id: 'a11a71b8-b775-42a4-8d73-25f3b0856404',
                          type: 'Nested',
                          name: 'D',
                        },
                        position: 1,
                      },
                      ]
                    },
                    {
                      id: '147b6488-2230-450f-b666-6f446ce652f6',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nesteds',
                      mode: nil,
                      editor: 'checkbox',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::HasMany',
                      possible_values: [{
                        value_record: {
                          id: 'cc3afe39-8a6b-4d28-bee3-97cabf6c4008',
                          type: 'Nested',
                          name: 'E',
                        },
                        position: 0,
                      },
                      {
                        value_record: {
                          id: 'b61d59d6-3fc5-4c29-a0c5-dec27d68ffb3',
                          type: 'Nested',
                          name: 'F',
                        },
                        position: 1,
                      },
                      ]
                    },
                  ],
                  serialized_record_for_input_prefix: {
                    'record@0': {
                      'id': nil,
                    },
                  },
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should assign different css ids to checkboxes' do
              expect(page).to have_css('#input-record-nesteds--value-0')
              expect(page).to have_css('#input-record-nesteds--value-1')
              expect(page).to have_css('#input-record-nesteds--1-value-0')
              expect(page).to have_css('#input-record-nesteds--1-value-1')
              expect(page).to have_css('#input-record-nesteds--2-value-0')
              expect(page).to have_css('#input-record-nesteds--2-value-1')
            end

            xit 'should change value in submission from different inputs' do # why <div class="form-check"> are not closed properly in tests but it is right in dynamo app ?
              find('#input-record-nesteds--value-0').click
              expect(page).to have_css('input[type="checkbox"][checked]', count: 1)
              find('#input-record-nesteds--2-value-0').click
              expect(page).to have_css('input[type="checkbox"][checked]', count: 2)
              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq({
                "record@0.nesteds@0" => {"id" => "6b56763c-cdb4-483e-bd3e-cf1cd65e129c"},
                "record@0.nesteds@1" => {"id" => "cc3afe39-8a6b-4d28-bee3-97cabf6c4008"}
              })
            end
          end

        end

      end
    end

    context 'element.mode = nested_form' do

      context 'dynamic_form' do
        context '' do
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
                  }, {
                    id: 3,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    type: 'Control::AddButton',
                    normalized_input_prefix: 'record@0.nesteds@0',
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
              dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
              Form(dynamic_form: dynamic_form)
            end
          end

          it 'should have correct values in input' do
            expect(find('input[name="record.nesteds@1[attr]"]').value).to eq('B')
          end

          it 'should render an add button' do
            expect(page).to have_css('.btn[href="#add"]', count: 1)
          end

          context 'click on add_button' do
            it 'should add elements for a new record' do
              find('.btn[href="#add"]').click
              expect(page).to have_css('input[name="record.nesteds@2[attr]"]')
            end
          end

          describe 'submission.params' do
            before(:each) do
              find('input[name="record.nesteds@1[attr]"]').set('C')
            end

            it 'should use input prefix for params keys' do
              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq(
                {
                  'record@0.nesteds@0' => { 'attr' => 'A' },
                  'record@0.nesteds@1' => { 'attr' => 'C' },
                }
              )
            end

          end
        end

        context 'with condition' do

          context 'existing record' do
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
                      attribute_name: 'nesteds',
                      normalized_input_prefix: 'record@0',
                      mode: 'nested_form',
                      type: 'Association::HasMany',
                      condition_formula: {"attr"=>{"equal"=>"A"}},
                    }, {
                      id: 2,
                      klass_name: 'Nested',
                      root_klass_name: 'Record',
                      method_names: ['nesteds'],
                      normalized_input_prefix: 'record@0.nesteds@0',
                      attribute_name: 'attr',
                      parent_id: 1,
                      type: 'Attribute::String',
                    }, {
                      id: 3,
                      klass_name: 'Nested',
                      root_klass_name: 'Record',
                      method_names: ['nesteds'],
                      type: 'Control::AddButton',
                      normalized_input_prefix: 'record@0.nesteds@0',
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
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should display only elements where record satisfy condition' do
              expect(has_css?('input[name="record.nesteds@0[attr]"]')).to eq true
              expect(has_css?('input[name="record.nesteds@1[attr]"]')).to eq false
            end

          end

          context 'min 1 with default value' do
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
                      attribute_name: 'nesteds',
                      normalized_input_prefix: 'record@0',
                      mode: 'nested_form',
                      type: 'Association::HasMany',
                      condition_formula: {"attr"=>{"equal"=>"A"}},
                      min: 1, # <-
                    }, {
                      id: 2,
                      klass_name: 'Nested',
                      root_klass_name: 'Record',
                      method_names: ['nesteds'],
                      normalized_input_prefix: 'record@0.nesteds@0',
                      attribute_name: 'attr',
                      parent_id: 1,
                      default_value: 'A', # <-
                      type: 'Attribute::String',
                    }, {
                      id: 3,
                      klass_name: 'Nested',
                      root_klass_name: 'Record',
                      method_names: ['nesteds'],
                      type: 'Control::AddButton',
                      normalized_input_prefix: 'record@0.nesteds@0',
                    }
                  ],
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should display only elements where record satisfy condition' do # should we always display elements for new records ?
              expect(has_css?('input[name="record.nesteds@0[attr]"]')).to eq true
            end
          end
        end

      end

      context 'record' do

        context '' do
          before(:each) do
            mount do
              record = Record.new(
                nesteds: [
                  Nested.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', attr: 'A'),
                  Nested.new(attr: 'B'),
                ]
              )

              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
          end

          it 'should have correct values in input' do
            expect(find('input[name="record[nesteds_attributes][0][attr]"]').value).to eq('A')
            expect(find('input[name="record[nesteds_attributes][1][attr]"]').value).to eq('B')
          end

          describe 'submission.params' do
            before(:each) do
              find('input[name="record[nesteds_attributes][1][attr]"]').set('C')
            end

            it 'should use nested attributes for params keys' do
              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq(
                {
                  'record' => {
                    'nesteds_attributes' => [
                      {
                        'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        'attr' => 'A',
                      },
                      {
                        'attr' => 'C',
                      },
                    ]
                  }
                }
              )
            end

          end

        end

        context 'with errors' do
          before(:each) do
            mount do
              record = Record.new(
                nesteds: [
                  Nested.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', attr: 'A'),
                  Nested.new(attr: ''),
                ]
              )
              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
            page_exec do
              # simulate errors from submit
              Form.current.submission.errors = {'nesteds[0].attr' => [{error: 'blank'}]}
              Form.current.mutate
            end
          end

          it 'should display an error' do
            expect(page).to have_css('.invalid-feedback')
          end
        end

        context 'orderable' do # note: more tests in control/item_header_spec.rb

          before(:each) do
            page_exec do
              class OrderableNested < HyperResource::Base
                attribute :position, type: Integer
              end
              class Record < HyperResource::Base
                has_many :orderable_nesteds, class_name: 'OrderableNested'
              end
            end
            mount do
              record = Record.new(
                orderable_nesteds: [
                  OrderableNested.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', attr: 'A', position: 0),
                  OrderableNested.new(attr: 'B', position: 2),
                  OrderableNested.new(id: '0188c494-8a31-7184-977e-261fdc3514df', attr: 'C', position: 1),
                ]
              )
              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'orderable_nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
          end

          it 'should have correct values in input' do
            expect(find('input[name="record[orderable_nesteds_attributes][0][attr]"]').value).to eq('A')
            expect(find('input[name="record[orderable_nesteds_attributes][1][attr]"]').value).to eq('B') # index in input must follow index in association
            expect(find('input[name="record[orderable_nesteds_attributes][2][attr]"]').value).to eq('C')
          end

          it 'should use nested attributes for params keys' do
            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record' => {
                  'orderable_nesteds_attributes' => [
                    {
                      'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      'attr' => 'A',
                      'position' => 0,
                    },
                    {
                      'attr' => 'B',
                      'position' => 2,
                    },
                    {
                      'id' => '0188c494-8a31-7184-977e-261fdc3514df',
                      'attr' => 'C',
                      'position' => 1,
                    },
                  ]
                }
              }
            )
          end

          describe 'submission.params' do
            before(:each) do
              find('input[name="record[orderable_nesteds_attributes][1][attr]"]').set('B2')
            end

            it 'should use nested attributes for params keys' do
              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq(
                {
                  'record' => {
                    'orderable_nesteds_attributes' => [
                      {
                        'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        'attr' => 'A',
                        'position' => 0,
                      },
                      {
                        'attr' => 'B2',
                        'position' => 2,
                      },
                      {
                        'id' => '0188c494-8a31-7184-977e-261fdc3514df',
                        'attr' => 'C',
                        'position' => 1,
                      },
                    ]
                  }
                }
              )
            end
          end

          it 'up should change position' do
            all('[href="#up"]')[2].click # B up
            expect(
              page_eval do
                  Form.current.submission.params.to_n
                end
            ).to eq(
              {
                'record' => {
                  'orderable_nesteds_attributes' => [
                    {
                      'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      'attr' => 'A',
                      'position' => 0,
                    },
                    {
                      'attr' => 'B',
                      'position' => 1,
                    },
                    {
                      'id' => '0188c494-8a31-7184-977e-261fdc3514df',
                      'attr' => 'C',
                      'position' => 2,
                    },
                  ]
                }
              }
            )
          end

          it 'down should change position' do
            all('[href="#down"]')[1].click # C down
            expect(
              page_eval do
                  Form.current.submission.params.to_n
                end
            ).to eq(
              {
                'record' => {
                  'orderable_nesteds_attributes' => [
                    {
                      'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      'attr' => 'A',
                      'position' => 0,
                    },
                    {
                      'attr' => 'B',
                      'position' => 1,
                    },
                    {
                      'id' => '0188c494-8a31-7184-977e-261fdc3514df',
                      'attr' => 'C',
                      'position' => 2,
                    },
                  ]
                }
              }
            )
          end

        end

        context 'min' do
          context 'empty association' do
            context '' do
              before(:each) do
                mount do
                  record = Record.new(
                    nesteds: []
                  )

                  Form(record: record) do
                    Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form', min: 1) do
                      Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'B')
                    end
                  end
                end
              end

              it 'should add additional elements' do
                expect(find('input[name="record[nesteds_attributes][0][attr]"]').value).to eq('B') # added
              end


              describe 'submission.params' do
                before(:each) do
                  find('input[name="record[nesteds_attributes][0][attr]"]').set('C')
                end

                it 'should add params in submission' do # ?
                  expect(
                    page_eval do
                      Form.current.submission.params.to_n
                    end
                  ).to eq(
                    {
                      'record' => {
                        'nesteds_attributes' => [
                          {
                            'attr' => 'C',
                          },
                        ]
                      }
                    }
                  )
                end
              end
            end

            context 'orderable' do
              before(:each) do
                mount do
                  class OrderableNested < HyperResource::Base
                    attribute :position, type: Integer
                  end
                  class Record < HyperResource::Base
                    has_many :orderable_nesteds, class_name: 'OrderableNested'
                  end
                  record = Record.new(
                    orderable_nesteds: []
                  )
                  Form(record: record) do
                    Form::Element::Association::HasMany(attribute_name: 'orderable_nesteds', mode: 'nested_form', min: 1) do
                      Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'B')
                    end
                  end
                end
              end

              it 'should set position to additional elements' do
                expect(
                  page_eval do
                    Form.current.submission.params.to_n # should be in submission ?
                  end
                ).to eq(
                  {
                    'record' => {
                      'orderable_nesteds_attributes' => [
                        {
                          'attr' => 'B',
                          'position' => 0,
                        },
                      ]
                    }
                  }
                )
              end
            end
          end

          context 'association with an element' do
            before(:each) do
              mount do
                record = Record.new(
                  nesteds: [Nested.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', attr: 'A')]
                )

                Form(record: record) do
                  Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form', min: 2) do
                    Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'B')
                  end
                end
              end
            end

            it 'should add additional elements' do
              expect(find('input[name="record[nesteds_attributes][0][attr]"]').value).to eq('A')
              expect(find('input[name="record[nesteds_attributes][1][attr]"]').value).to eq('B') # added
            end

            describe 'submission.params' do
              before(:each) do
                find('input[name="record[nesteds_attributes][1][attr]"]').set('C')
              end

              it 'should use nested attributes for params keys' do
                expect(
                  page_eval do
                    Form.current.submission.params.to_n
                  end
                ).to eq(
                  {
                    'record' => {
                      'nesteds_attributes' => [
                        {
                          'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                          'attr' => 'A',
                        },
                        {
                          'attr' => 'C',
                        },
                      ]
                    }
                  }
                )
              end
            end
          end

          it 'an empty association should not crash other fields due to missing id' do
            mount do
              record = Record.new(
                nesteds: []
              )
              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form', min: 1) do
                  Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'B')
                end
                Form::Element::Association::HasMany(attribute_name: 'nesteds') # for check it doesn't crash
              end
            end
            expect(find('input[name="record[nesteds_attributes][0][attr]"]').value).to eq('B') # added

            find('.ts-control .item', count: 1) # why text is empty ?
          end
        end

        context 'association in an association' do
          before(:each) do
            page_exec do
              class NestedNested < HyperResource::Base
              end
              class Nested < HyperResource::Base
                has_many :nested_nesteds, class_name: 'NestedNested'
              end
            end
          end

          xit 'should render children elements of children elements' do # TODO make this test pass (needed for chart groups ranges)
            mount do
              Form(record: Record.new(nesteds: [Nested.new(nested_nesteds: NestedNested.new(attr: 'toto'))])) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Association::HasMany(attribute_name: 'nested_nesteds', mode: 'nested_form') do
                    Form::Element::Attribute::String(attribute_name: 'attr')
                  end
                end
              end
            end

            expect(
              has_css?('input[name="record[nesteds_attributes][0][nested_nesteds_attributes][0][attr]"]')
            ).to eq true

            find('input[name="record[nesteds_attributes][0][nested_nesteds_attributes][0][attr]"]').set('titi')

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq({"record" => {"nesteds_attributes" => [{"nested_nesteds_attributes" => [{"attr"=>"titi"}]}]}})
          end
        end

        context 'belongs_to in an association' do
          before(:each) do
            page_exec do
              class NestedNested < HyperResource::Base
              end
              class Nested < HyperResource::Base
                belongs_to :value_record, polymorphic: true
              end
            end
            page_exec do
              stub_request(:get, "/records.json?term=&select2=true").to_return do |request|
                {
                  status: 200,
                  body: {
                    results: [{
                      id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      text: 'nested 1',
                      record: {
                        id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        name: 'nested 1',
                      },
                    }, {
                      id: '2caf771d-7a92-40bb-908c-3c835e054367',
                      text: 'nested 2',
                      record: {
                        id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        name: 'nested 2',
                      },
                    }]
                  }.to_json,
                }
              end
            end
            mount do
              record = Record.new(
                nesteds: [Record.new(value_record: Nested.new(name: 'nested 2', id: '2caf771d-7a92-40bb-908c-3c835e054367'))]
              )
              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Association::BelongsTo(attribute_name: 'value_record', target_klass: Record, polymorphic: true)
                end
                Form::Element::Control::AddButton(attribute_name: 'nesteds')
              end
            end
          end

          it 'should render' do
            expect(
              has_css?('select[name="record[nesteds_attributes][0][value_record]"]')
            ).to eq true
            expect(page).to have_content('nested 2')
          end

          it 'should submit params' do
            find('select[name="record[nesteds_attributes][0][value_record]"]+.ts-wrapper').click
            find('.ts-dropdown  .option', text: 'nested 1').click

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq({"record" => {"nesteds_attributes" => [{"value_record" => {"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b", "type"=>"Record"}}]}})
          end
        end

        context 'boolean in an association' do
          before(:each) do
            page_exec do
              class Nested < HyperResource::Base
              end
            end
            mount do
              record = Record.new(
                nesteds: [Record.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', bool_attr: true)]
              )
              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::Boolean(attribute_name: 'bool_attr')
                end
              end
            end
          end

          it 'should render' do
            expect(
              has_css?('input[name="record[nesteds_attributes][0][bool_attr]"][checked]')
            ).to eq true
          end

          it 'should submit params' do
            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq({"record" => {"nesteds_attributes" => [{"id" => '17ad7795e-9899-47a9-a38f-6c1ead61991b', "bool_attr" => '1'}]}})
            find('input[name="record[nesteds_attributes][0][bool_attr]"]').click
            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq({"record" => {"nesteds_attributes" => [{"id" => '17ad7795e-9899-47a9-a38f-6c1ead61991b', "bool_attr" => '0'}]}})
          end
        end

        context 'with add button' do
          context 'empty association' do
            before(:each) do
              mount do
                record = Record.new(
                  nesteds: []
                )

                Form(record: record) do
                  Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                    Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'C')
                  end
                  Form::Element::Control::AddButton(attribute_name: 'nesteds')
                end
              end
            end

            it 'should display add button' do
              expect(page).to have_css('.btn[href="#add"]', count: 1)
            end

            it 'should add when click on button' do
              expect(page).to have_css('input', count: 0)
              find('.btn[href="#add"]').click
              expect(page).to have_css('input', count: 1)
              expect(find('input[name="record[nesteds_attributes][0][attr]"]').value).to eq('C')
            end
          end

          context 'association with two elements' do
            before(:each) do
              mount do
                record = Record.new(
                  nesteds: [Record.new(id: '17ad7795e-9899-47a9-a38f-6c1ead61991b', attr: 'A'), Record.new(attr: 'B')]
                )

                Form(record: record) do
                  Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                    Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'C')
                  end
                  Form::Element::Control::AddButton(attribute_name: 'nesteds')
                end
              end
            end

            it 'should add when click on button' do
              expect(page).to have_css('input', count: 2)
              find('.btn[href="#add"]').click
              expect(page).to have_css('input', count: 3)
              expect(find('input[name="record[nesteds_attributes][2][attr]"]').value).to eq('C')
            end

          end
        end

        context 'max' do
          before(:each) do
            mount do
              record = Record.new(
                nesteds: [Nested.new(attr: 'A')]
              )

              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form', max: 1) do
                  Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'B')
                end
                Form::Element::Control::AddButton(attribute_name: 'nesteds')
              end
            end
          end
          xit 'should not display the add button when max is reached' do # or at least disable it
            expect(page).to_not have_css('.btn[href="#add"]')
          end
        end

        context 'already initialized in a not nested form' do
          before(:each) do
            mount do
              record = Record.new(
                nesteds: [
                  Nested.new(id: '01a0103c-0cb0-72cd-a873-f3daa990b91a', attr: 'A'),
                  Nested.new(id: '01a0103e-8198-7df9-930e-0d7e39dfd868', attr: 'B'),
                ]
              )

              Form(record: record) do
                Form::Element::Association::HasMany(attribute_name: 'nesteds')
                Form::Element::Association::HasMany(attribute_name: 'nesteds', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'attr')
                end
              end
            end
          end

          it 'should have correct values in input' do
            expect(find('input[name="record[nesteds_attributes][0][attr]"]').value).to eq('A')
            expect(find('input[name="record[nesteds_attributes][1][attr]"]').value).to eq('B')
          end

          describe 'submission.params' do
            before(:each) do
              find('input[name="record[nesteds_attributes][1][attr]"]').set('C')
            end

            it 'should use nested attributes for params keys' do
              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq(
                {
                  'record' => {
                    'nesteds_attributes' => [
                      {
                        'id' => '01a0103c-0cb0-72cd-a873-f3daa990b91a',
                        'attr' => 'A',
                      },
                      {
                        'id' => '01a0103e-8198-7df9-930e-0d7e39dfd868',
                        'attr' => 'C',
                      },
                    ]
                  }
                }
              )
            end

          end

          xit 'change not nested should rerender nested form' # how to do that without rerender the entire form ?

        end

      end

    end

  end

  context 'form.mode = edit_in_place' do

    context 'empty' do
      before(:each) do
        page_exec do
          stub_request(:get, '/nesteds.json?owner_klass_name=Record&association_name=nesteds&select2=true').to_return do |request|
            {
              status: 200,
              body: {
                results: [{
                  id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  text: 'nested 1',
                  record: {
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    name: 'nested 1',
                  },
                }, {
                  id: '2caf771d-7a92-40bb-908c-3c835e054367',
                  text: 'nested 2',
                  record: {
                    id: '2caf771d-7a92-40bb-908c-3c835e054367',
                    name: 'nested 2',
                  },
                }]
              }.to_json,
            }
          end
          stub_request(:patch, /records/).to_return do |request|
            {
              status: 200,
              body: {
                id: '9f74305a-66a4-410b-9b35-bdc1c190186b',
                nested_ids: ['17ad7795e-9899-47a9-a38f-6c1ead61991b'],
              }.to_json,
            }
          end
        end

        mount do
          dynamic_form = Dynamic::Form.new(
            id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'nesteds',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::HasMany',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should show an input when click' do
        expect(page).to_not have_css('input')
        find('.form-control').click
        expect(page).to have_css('input')
      end

      it 'should open a autocomplete' do
        find('.form-control').click # enable editing
        find('.form-control').click
        expect(page).to have_css('.dropdown-menu')
        expect(page).to have_css('.dropdown-item')
        expect(page).to have_content('nested 1')
        expect(page).to have_content('nested 2')
      end

      it 'should update value when click on autocomplete item' do
        find('.form-control').click # enable editing
        find('.form-control').click # open autocomplete
        find('.dropdown-item', text: 'nested 1').click # click on item
        expect(page).to have_css('.fa-check') # record is successfully updated
        expect(page).to_not have_css('.dropdown-menu') # autocomplete is hidden
        expect(page).to have_content('nested 1') # updated value is displayed
        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq(
          {
            "record@0.nesteds@0" => {"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b"},
          }
        )
      end

    end

    context 'not empty' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'nesteds',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::HasMany',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
              },
              'record@0.nesteds@0': {
                id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                name: 'nested 1',
                photo: {
                  attachment: {
                    signed_id: 'signed_id', # in reality it is a lonnng id
                    filename: 'photo.png',
                  }
                }
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it "should show record's name" do
        expect(page).to have_content('nested 1')
      end

      xit "should show record's photo" do # can't mock native http requests that comes from browser (it needs a chrome extension like oh-my-mock)
        expect(page).to have_css('img[src="/api/files/blobs/signed_id/photo.png"]')
      end

      context 'and then remove value' do
        before(:each) do
          page_exec do
            stub_request(:get, '/nesteds.json?owner_klass_name=Record&association_name=nesteds&select2=true').to_return do |request|
              {
                status: 200,
                body: {
                  results: [{
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    text: 'nested 1',
                    record: {
                      id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      name: 'nested 1',
                    },
                  }, {
                    id: '2caf771d-7a92-40bb-908c-3c835e054367',
                    text: 'nested 2',
                    record: {
                      id: '2caf771d-7a92-40bb-908c-3c835e054367',
                      name: 'nested 2',
                    },
                  }]
                }.to_json,
              }
            end
            stub_request(:patch, /records/).to_return do |request|
              params = ::JSON.parse(request.body)
              nested_ids = params['record']['nested_ids']
              {
                status: 200,
                body: {
                  id: '9f74305a-66a4-410b-9b35-bdc1c190186b',
                  nested_ids: nested_ids,
                }.to_json,
              }
            end
          end
          find('.form-control').click
          find('[href="#remove"]').click
        end

        it "should remove record's name" do
          expect(page).to_not have_content('nested 1')
        end

        context 'and then re-add the same value' do
          before(:each) do
            find('.form-control').click
            find('.form-control').click
            find('.dropdown-item', text: 'nested 1').click # click on item
          end

          it "should show again record's name" do
            expect(page).to have_content('nested 1')
          end

          context 'and then re-remove the value' do
            before(:each) do
              find('.form-control').click
              find('[href="#remove"]').click
            end

            it "should remove again record's name" do
              expect(page).to_not have_content('nested 1')
            end
          end
        end
      end
    end

    context 'polymorphic' do
      before(:each) do
        page_exec do
          class Object
            def self.search_path(parameters = {})
              return "/nesteds.json"
            end
          end

          class Record < HyperResource::Base
            has_many :polymorphic_nesteds, polymorphic: true
          end

          stub_request(:get, '/nesteds.json?select2=true').to_return do |request|
            {
              status: 200,
              body: {
                results: [{
                  id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  text: 'nested 1',
                  record: {
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    name: 'nested 1',
                    type: 'Nested',
                  },
                }, {
                  id: '2caf771d-7a92-40bb-908c-3c835e054367',
                  text: 'nested 2',
                  record: {
                    id: '2caf771d-7a92-40bb-908c-3c835e054367',
                    name: 'nested 2',
                    type: 'Nested',
                  },
                }]
              }.to_json,
            }
          end
          stub_request(:patch, '/records/bfe6e73c-a3a8-4f0b-8eaf-b35f90110309.json').to_return do |request|
            body = {
              "record": {
                "polymorphic_nested_ids": [{'id' => "17ad7795e-9899-47a9-a38f-6c1ead61991b", 'type' => 'Nested'}],
              },
              "versioning": {
                "source_type":"Dynamic::Form",
                "source_id":"c3fe8d40-4950-49ce-b107-7dc181599aac",
              },
            }
            if request.params == body
              {
                status: 200,
                body: {
                  id: '9f74305a-66a4-410b-9b35-bdc1c190186b',
                  polymorphic_nesteds: [
                    {
                      'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      'type' => 'Nested',
                    }
                  ]
                }.to_json,
              }
            else
              {
                status: 422
              }
            end
          end
        end

        mount do
          dynamic_form = Dynamic::Form.new(
            id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'polymorphic_nesteds',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::HasMany',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should update value when click on autocomplete item' do
        find('.form-control').click # enable editing
        find('.form-control').click # open autocomplete
        find('.dropdown-item', text: 'nested 1').click # click on item
        expect(page).to have_css('.fa-check') # record is successfully updated
        expect(page).to_not have_css('.dropdown-menu') # autocomplete is hidden
        expect(page).to have_content('nested 1') # updated value is displayed
        expect(
          page_eval do
            Form.current.submission.params.to_n
          end
        ).to eq(
          {
            "record@0.polymorphic_nesteds@0" => {"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b", "type"=>"Nested"}
          }
        )
      end

    end

    context 'requirement = mandatory' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                requirement: 'mandatory',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'nesteds',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::HasMany',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
              },
              'record@0.nesteds@0': {
                id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                name: 'nested 1',
                photo: {
                  attachment: {
                    signed_id: 'signed_id', # in reality it is a lonnng id
                    filename: 'photo.png',
                  }
                }
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'submit should fail if value is not present' do
        find('.form-control').click
        find('a[href="#remove"]').click # remove last nested
        expect(page).to have_selector('.fa-times')
      end
    end

    context 'element.mode = nested_form' do
      context 'with a belongs_to inside nested_form' do
        before(:each) do
          page_exec do
            class Nested < HyperResource::Base
              belongs_to :record, class_name: 'Record'
            end
          end
          mount do
            dynamic_form = Dynamic::Form.new(
              id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
              klass_name: 'Record',
              mode: 'edit_in_place',
              elements: [
                {
                  id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                  klass_name: 'Record',
                  root_klass_name: 'Record',
                  method_names: [],
                  attribute_name: 'nesteds',
                  mode: 'nested_form',
                  normalized_input_prefix: 'record@0',
                  type: 'Association::HasMany',
                },
                {
                  id: 'a594d9a2-0141-496b-9b07-3a302c67dcd1',
                  parent_id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                  klass_name: 'Record',
                  root_klass_name: 'Record',
                  method_names: ['nesteds'],
                  attribute_name: 'record',
                  mode: 'edit_in_place',
                  normalized_input_prefix: 'record@0.nesteds@0.record@0',
                  type: 'Association::BelongsTo',
                },
              ],
              serialized_record_for_input_prefix: {
                'record@0': {
                  'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
                },
                'record@0.nesteds@0': {
                  id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  name: 'nested 1',
                  photo: {
                    attachment: {
                      signed_id: 'signed_id', # in reality it is a lonnng id
                      filename: 'photo.png',
                    }
                  }
                },
                'record@0.nesteds@0.record@0': {
                  id: '13a11cac-09e7-4e59-8216-d109e57fe5cc',
                  name: 'belongs_to inside nested form',
                },
              },
            )
            dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
            Form(dynamic_form: dynamic_form)
          end
        end

        it 'should display an input in edit in place for the belongs_to' do
          expect(page).to have_content('belongs_to inside nested form')
        end
      end

    end
  end

  context 'form.mode = read_only' do
    before(:each) do
      mount do
        dynamic_form = Dynamic::Form.new(
          id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
          klass_name: 'Record',
          mode: 'read_only',
          elements: [
            {
              id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
              klass_name: 'Record',
              root_klass_name: 'Record',
              method_names: [],
              attribute_name: 'nesteds',
              mode: nil,
              normalized_input_prefix: 'record@0',
              type: 'Association::HasMany',
            },
          ],
            serialized_record_for_input_prefix: {
            'record@0.nesteds@0': {
              name: 'A'
            },
            'record@0.nesteds@1': {
              name: 'B',
            },
          },
        )
        dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
        Form(dynamic_form: dynamic_form)
      end
    end

    it 'display items with links' do
      expect(page).to have_css('a', count: 2)
      expect(page).to have_content('A')
      expect(page).to have_content('B')
    end

  end

end
