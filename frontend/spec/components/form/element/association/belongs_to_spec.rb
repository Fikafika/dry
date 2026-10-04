describe 'Form::Element::Association::BelongsTo', type: :system do
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
        belongs_to :nested, class_name: 'Nested'
      end
    end
  end

  context 'mode = edit_in_place' do

    context 'empty' do
      before(:each) do
        page_exec do
          stub_request(:get, '/nesteds.json?owner_klass_name=Record&association_name=nested&select2=true').to_return do |request|
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
                nested_id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
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
                attribute_name: 'nested',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::BelongsTo',
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
        find('.form-control').click
        expect(page).to have_css('.dropdown-menu')
        expect(page).to have_css('.dropdown-item')
        expect(page).to have_content('nested 1')
        expect(page).to have_content('nested 2')
      end

      it 'should update value when click on autocomplete item' do
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
            "record@0.nested@0" => {"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b"},
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
                attribute_name: 'nested',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::BelongsTo',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
              },
              'record@0.nested@0': {
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
            belongs_to :polymorphic_nested, polymorphic: true
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
                "polymorphic_nested_id": "17ad7795e-9899-47a9-a38f-6c1ead61991b",
                "polymorphic_nested_type": "Nested",
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
                  nested_id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  nested_type: 'Nested',
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
                attribute_name: 'polymorphic_nested',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::BelongsTo',
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
            "record@0.polymorphic_nested@0" => {"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b", "type"=>"Nested"},
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
                attribute_name: 'nested',
                mode: 'edit_in_place',
                normalized_input_prefix: 'record@0',
                type: 'Association::BelongsTo',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                'id': 'bfe6e73c-a3a8-4f0b-8eaf-b35f90110309',
              },
              'record@0.nested@0': {
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
        page_exec do
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
          stub_request(:patch, '/records/bfe6e73c-a3a8-4f0b-8eaf-b35f90110309.json').to_return do |request|
            if request.params.dig(:record, :nested_id).nil?
              { status: 422 }
            else
              { status: 200, body: {} }
            end
          end
        end
      end

      it 'submit should fail if value is not present' do
        find('.form-control').click
        find('input[type=text]').send_keys(:backspace, :enter)
        expect(page).to have_selector('.fa-times')
      end
    end
  end

  context 'mode = edit_cell' do

    context 'autocomplete with a variable not displayed in the form' do
      before(:each) do
        page_exec do
          class Owner < HyperResource::Base
            def self.api_path
              '/owners'
            end
          end
          class Record < HyperResource::Base
            belongs_to :owner, class_name: 'Owner'
          end

          stub_request(:get, /nesteds\.json.*variables%5Bowner%5D=0189b658-bd4e-787c-a301-fc40f1cf9e1e/).to_return do |request|
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
                }]
              }.to_json,
            }
          end
        end

        mount do
          record = Record.new(
            id: '9f74305a-66a4-410b-9b35-bdc1c190186b',
            owner: Owner.new(id: '0189b658-bd4e-787c-a301-fc40f1cf9e1e'),
          )
          Form(record: record) do
            Form::Element::Association::BelongsTo(
              attribute_name: 'owner',
              editor: 'hidden',
              show_label: false,
            )
            Form::Element::Association::BelongsTo(
              attribute_name: 'nested',
              mode: :edit_cell,
              autocomplete_filters: {owner: {variable: 'owner'}},
            )
          end
        end
      end

      it 'should resolve the variable from the hidden element' do
        find('input.form-control').click
        expect(page).to have_content('nested 1')
      end
    end

    context 'autocomplete with a has_many variable rendered like the cell editor' do
      before(:each) do
        page_exec do
          class Tutor < HyperResource::Base
            def self.api_path
              '/tutors'
            end
          end
          class Record < HyperResource::Base
            has_many :tutors, class_name: 'Tutor'
          end

          stub_request(:get, /nesteds\.json.*variables%5Btutors%5D%5B%5D=0189b658-bd4e-787c-a301-fc40f1cf9e1e/).to_return do |request|
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
                }]
              }.to_json,
            }
          end
        end

        mount do
          record = Record.new(
            id: '9f74305a-66a4-410b-9b35-bdc1c190186b',
            tutors: [Tutor.new(id: '0189b658-bd4e-787c-a301-fc40f1cf9e1e')],
          )
          Form(record: record) do
            Form::Element.klass_from_method_name(Record, 'tutors').create_element(
              key: 'tutors',
              attribute_name: 'tutors',
              editor: 'hidden',
              show_label: false,
            ).render
            Form::Element::Association::BelongsTo(
              attribute_name: 'nested',
              mode: :edit_cell,
              autocomplete_filters: {tutors: {contains_id: {variable: 'tutors'}}},
            )
          end
        end
      end

      it 'should resolve the has_many variable from the hidden element' do
        find('input.form-control').click
        expect(page).to have_content('nested 1')
      end
    end

  end

  context 'mode = nested form' do

    context 'dynamic' do
      before(:each) do
        page_eval do
          $dynamic_form_attributes = {
            id: 1,
            klass_name: 'Record',
            mode: 'input',
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
              }, {
                id: 2,
                klass_name: 'Nested',
                root_klass_name: 'Record',
                method_names: ['nested'],
                normalized_input_prefix: 'record@0.nested@0',
                attribute_name: 'attr',
                parent_id: 1,
                type: 'Attribute::String',
              }
            ],
            serialized_record_for_input_prefix: {
            },
          }
        end
      end

      context 'empty' do
        before(:each) do
          mount do
            dynamic_form = Dynamic::Form.new($dynamic_form_attributes)
            dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
            Form(dynamic_form: dynamic_form)
          end
        end

        it 'should render nested inputs' do
          expect(page).to have_css('input[name="record.nested@0[attr]"]')
        end

      end

      context 'not empty' do
        before(:each) do
          mount do
            $dynamic_form_attributes['serialized_record_for_input_prefix'] = {
              'record@0.nested@0': {
                attr: 'A'
              },
            }
            dynamic_form = Dynamic::Form.new($dynamic_form_attributes)
            dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
            Form(dynamic_form: dynamic_form)
          end
        end

        describe 'submission.params' do
          before(:each) do
            find('input[name="record.nested@0[attr]"]').set('C')
          end

          it 'should use input prefix for params keys' do
          expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record@0.nested@0' => { 'attr' => 'C' },
              }
            )
          end

        end

      end

      context 'errors' do
        before(:each) do
          page_exec do
            stub_request(:post, '/api/dynamic/schemas//forms/1/submit.json').to_return do |request|
              {
                status: 422,
                body: {
                  'record.nested': {
                    attr: [{ error: 'blank' }]
                  }
                }.to_json,
              }
            end
          end
          mount do
            dynamic_form = Dynamic::Form.new($dynamic_form_attributes)
            dynamic_form.status_code = 200
            Form(dynamic_form: dynamic_form) do
              Form::Footer()
            end
          end
        end

        it 'should have element with is-invalid' do
          find('input[name="record.nested@0[attr]"]').set(' ')
          find('.btn-primary').click
          expect(page).to have_css('.is-invalid')
        end

      end

    end

    context 'record' do

      context '' do
        before(:each) do
          mount do
            record = Record.new(
              nested: Nested.new(attr: 'A')
            )

            Form(record: record) do
              Form::Element::Association::BelongsTo(attribute_name: 'nested', mode: 'nested_form') do
                Form::Element::Attribute::String(attribute_name: 'attr')
              end
            end
          end
        end

        xdescribe 'submission.params' do
          before(:each) do
            find('input[name="record[nested_attributes][0][attr]"]').set('C') # TODO fix to have record[nested_attributes][attr]
          end

          it 'should use nested attributes for params keys' do
            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record' => {
                  'nested_attributes' => {
                    'attr' => 'C',
                  },
                }
              }
            )
          end

        end
      end

      context 'min' do

        it 'an empty association should not crash other fields due to missing id' do
          mount do
            record = Record.new
            Form(record: record) do
              Form::Element::Association::BelongsTo(attribute_name: 'nested', mode: 'nested_form', min: 1) do
                Form::Element::Attribute::String(attribute_name: 'attr', default_value: 'B')
              end
              Form::Element::Association::BelongsTo(attribute_name: 'nested') # for check it doesn't crash
            end
          end
          expect(find('input[name="record[nested_attributes][0][attr]"]').value).to eq('B') # added

          find('.tomselected option', count: 1) # why text is empty ?
        end

      end

    end

  end

  context 'form.mode = input' do

    context 'element.mode = default' do

      context 'editor = radio' do

        context 'dynamic_form' do
          context '' do
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
                      attribute_name: 'nested',
                      mode: nil,
                      editor: 'radio',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::BelongsTo',
                      value_position: 'right',
                      inline: true,
                      possible_values: [
                        {
                          value_record: {
                            id: 'f0e19422-c637-460b-aa49-b1819d9f300d',
                            type: 'Nested',
                            name: 'Toto',
                          },
                          translations: [{
                            text: 'A',
                            locale: 'fr',
                          }],
                          position: 0,
                        },
                        {
                          value_record: {
                            id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                            type: 'Nested',
                            name: 'Titi',
                          },
                          translations: [{
                            text: 'B',
                            locale: 'fr',
                          }],
                          position: 1,
                        },
                      ],
                      default_value_record: {
                        id: 'f0e19422-c637-460b-aa49-b1819d9f300e',
                        type: 'Nested',
                        name: 'Titi',
                      },
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

            it 'should show radio buttons' do
              expect(page).to have_css('input[type="radio"]', count: 2)
            end

            it 'should have possible_value text as label' do
              expect(find(:xpath, "//label[@for='input-record-nested-value-0']")).to have_content('A')
              expect(find(:xpath, "//label[@for='input-record-nested-value-1']")).to have_content('B')
            end

            it 'default value should be checked' do
              expect(find("input[id='input-record-nested-value-0']")).to_not be_checked
              expect(find("input[id='input-record-nested-value-1']")).to be_checked
            end

            it 'click on item' do
              find("input[id='input-record-nested-value-0']").click
              expect(find("input[id='input-record-nested-value-0']")).to be_checked
              expect(find("input[id='input-record-nested-value-1']")).to_not be_checked
            end

            describe 'submission.params' do
              before(:each) do
                find("input[id='input-record-nested-value-0']").click
                expect(find("input[id='input-record-nested-value-0']")).to be_checked
              end

              it 'should write in submission' do
                expect(
                  page_eval do
                    Form.current.submission.params.to_n
                  end
                ).to eq(
                  {
                    "record@0.nested@0" => {
                      "id" => 'f0e19422-c637-460b-aa49-b1819d9f300d'
                    }
                  }
                )
              end
            end
          end

          context 'when no possible values' do
            before(:each) do
              page_exec do
                stub_request(:get, /\/nesteds\.json/).to_return do |request|
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
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'nested',
                      mode: nil,
                      editor: 'radio',
                      normalized_input_prefix: 'record@0',
                      type: 'Association::BelongsTo',
                      value_position: 'right',
                      inline: true,
                      possible_values: [ ]
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

            it 'should display radio button' do
              expect(page).to have_css('input[type="radio"]', count: 2)
              expect(page).to have_content('nested 1')
              expect(page).to have_content('nested 2')
            end
          end
        end

      end

      context 'editor = select2' do
        context 'record' do
          before(:each) do
            page_exec do
              stub_request(:get, "/nesteds.json?term=&select2=true").to_return do |request|
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

          context 'attribute_name without _id' do

            context 'without default_value' do
              before(:each) do
                mount do
                  record = Record.new

                  Form(record: record) do
                    Form::Element::Association::BelongsTo(attribute_name: 'nested', target_klass: Nested, polymorphic: true)
                  end.on(:change) do
                    Form.current.mutate # in order to trigger more potential bug when rerender
                  end
                end
              end

              it 'should render' do
                expect(
                  has_css?('select[name="record[nested]"]')
                ).to eq true
              end

              context 'change value' do
                before(:each) do
                  find('select[name="record[nested]"]+.ts-wrapper').click
                  find('.ts-dropdown .option', text: 'nested 1').click
                end

                it 'should change submission params' do
                  expect(
                    page_eval do
                      Form.current.submission.params.to_n
                    end
                  ).to eq({"record" => {"nested" => {"id"=>"17ad7795e-9899-47a9-a38f-6c1ead61991b", "type"=>"Nested"}}})
                end

                it 'should display selected value' do
                  expect(page).to have_css('.ts-control .item', text: 'nested 1')
                end

                it 'should display new selected value if changed again' do
                  find('select[name="record[nested]"]+.ts-wrapper').click
                  find('.ts-dropdown .option', text: 'nested 2').click
                  expect(page).to have_css('.ts-control .item', text: 'nested 2')
                end
              end
            end

            context 'with default_value' do
              before(:each) do
                mount do
                  record = Record.new
                  default_record = Nested.new(id: '2caf771d-7a92-40bb-908c-3c835e054367', name: 'nested 2')

                  Form(record: record) do
                    Form::Element::Association::BelongsTo(attribute_name: 'nested', target_klass: Nested, polymorphic: true, default_value: default_record)
                  end
                end
              end

              it 'default value should be selected' do
                expect(page).to have_css('.ts-control .item', text: 'nested 2')
              end
            end

            context 'filled by an autocomplete of another field' do
              before(:each) do
                mount do
                  record = Record.new
                  Form(record: record) do
                    Form::Element::Association::BelongsTo(attribute_name: 'nested', target_klass: Nested, polymorphic: true)
                  end
                end
                expect(page).to have_css('select[name="record[nested]"]')
                page_exec do
                  # simulate filled by autocomplete
                  Form.current.submission.write(['record', 'nested'], {id: '2caf771d-7a92-40bb-908c-3c835e054367', type: 'Nested'})
                  Form.current.submission.data['record'] = {'nested' => Nested.new(id: '2caf771d-7a92-40bb-908c-3c835e054367', name: 'nested 2') }
                  Form.current.mutate
                end
              end

              it 'should display value' do
                expect(page).to have_css('.ts-control .item', text: 'nested 2')
              end
            end

            context 'with existing value_id' do
              before(:each) do
                page_exec do
                  stub_request(:get, "/nesteds/2caf771d-7a92-40bb-908c-3c835e054367.json").to_return do |request|
                    {
                      status: 200,
                      body: {
                        id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        name: 'nested 2',
                      }.to_json,
                    }
                  end
                end

                mount do
                  record = Record.new(nested_id: '2caf771d-7a92-40bb-908c-3c835e054367')
                  Form(record: record) do
                    Form::Element::Layout::Column() do # in order to be sure it will load data even if it is a descendent element of form (nota: doesn't work if you use a DIV)
                      Form::Element::Association::BelongsTo(attribute_name: 'nested')
                    end
                  end
                end
              end

              it 'should retrieve additional data' do
                expect(page).to have_css('.ts-control .item', text: 'nested 2')
              end
            end

            context 'errors' do
              before(:each) do
                mount do
                  record = Record.new
                  record.errors = {'nested' => [{'error' => 'blank'}]}
                  Form(record: record) do
                    Form::Element::Association::BelongsTo(attribute_name: 'nested', target_klass: Nested, polymorphic: true)
                  end
                end
              end

              it 'should have element with is-invalid' do
                expect(page).to have_css('.is-invalid')
              end
            end

          end

          context 'attribute_name with _id' do # used for instance in setting of klasses

            context 'with existing value' do
              before(:each) do
                mount do
                  record = Record.new(nested: Nested.new(id: '2caf771d-7a92-40bb-908c-3c835e054367', name: 'nested 2'))
                  Form(record: record) do
                    Form::Element::Association::BelongsTo(attribute_name: 'nested_id')
                  end
                end
              end

              it 'should render value' do
                expect(page).to have_css('.ts-control .item', text: 'nested 2')
              end
            end

          end
        end

        context 'dynamic_form' do

          context 'default_value' do
            context 'polymorphic' do
              before(:each) do
                page_exec do
                  class Record < HyperResource::Base
                    belongs_to :polymorphic_nested, polymorphic: true
                  end
                end

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
                        attribute_name: 'polymorphic_nested',
                        normalized_input_prefix: 'record@0',
                        type: 'Association::BelongsTo',
                        default_value_record: Nested.new(id: '0197647b-9c40-7754-a51a-0728d123364b', name: 'nested 1'),
                      },
                    ],
                  )
                  dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                  Form(dynamic_form: dynamic_form)
                end
              end

              it 'fill submission' do
                expect(
                  page_eval do
                    Form.current.submission.params.to_n
                  end
                ).to eq(
                  {
                    "record@0.polymorphic_nested@0" => {"id"=>"0197647b-9c40-7754-a51a-0728d123364b", "type" => "Nested"},
                  }
                )
              end

              it 'should select nested record' do
                expect(page).to have_content('nested 1')
              end
            end
          end

          context 'autocomplete with a variable from a form params' do
            before(:each) do
              page_exec do
                class Contact < HyperResource::Base
                  def self.api_path
                    '/contacts'
                  end
                  has_many :phones, class_name: 'Phone', inverse_of: :owner
                  has_many :smses, class_name: 'Sms', inverse_of: :owner
                end
                class Phone < HyperResource::Base
                  def self.api_path
                    '/phones'
                  end
                  belongs_to :owner, polymorphic: true
                  has_many :smses, class_name: 'Sms', inverse_of: :phone
                end
                class Sms < HyperResource::Base
                  def self.api_path
                    '/smses'
                  end
                  belongs_to :phone, class_name: 'Phone'
                  belongs_to :owner, polymorphic: true
                end

                stub_request(:get, '/phones.json?filters=(and%3A!((owner%3A(variable%3Aowner))))&owner_klass_name=Sms&association_name=phone&term=&select2=true&variables%5Bowner%5D=0189b658-bd4e-787c-a301-fc40f1cf9e1e').to_return do |request|
                  {
                    status: 200,
                    body: {
                      results: [{
                        id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        text: '061345678',
                        record: {
                          id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                        },
                      }, {
                        id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        text: '9876441212',
                        record: {
                          id: '2caf771d-7a92-40bb-908c-3c835e054367',
                        },
                      }]
                    }.to_json,
                  }
                end
              end

              mount do
                dynamic_form = Dynamic::Form.new(
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Sms',
                  mode: 'input',
                  association_klass_name: 'Contact',
                  association_name: 'smses',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Sms',
                      root_klass_name: 'Sms',
                      method_names: [],
                      attribute_name: 'phone',
                      normalized_input_prefix: 'sms@0',
                      type: 'Association::BelongsTo',
                      autocomplete_filters: {owner: {variable: 'owner'}}
                    },
                  ],
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form, target_record_id: '0189b658-bd4e-787c-a301-fc40f1cf9e1e', target_record_type: 'Contact')
              end
            end

            it 'should filter autocomplete result' do
              find('select[name="sms[phone]"]+.ts-wrapper').click
              expect(page).to have_content('061345678')
            end
          end

          context 'autocomplete with a variable from an element with default value' do
            before(:each) do
              page_exec do
                class Commande < HyperResource::Base
                  def self.api_path
                    '/commandes'
                  end
                  belongs_to :vente, class_name: 'Vente'
                  belongs_to :produit, class_name: 'Produit' # todo same test with has_many
                end
                class Produit < HyperResource::Base
                  def self.api_path
                    '/produits'
                  end
                  belongs_to :vente, class_name: 'Vente'
                end
                class Vente < HyperResource::Base
                  def self.api_path
                    '/ventes'
                  end
                end

                stub_request(:get, '/produits.json?filters=(and%3A!((vente%3A(variable%3Avente))))&owner_klass_name=Commande&association_name=produit&term=&select2=true&variables%5Bvente%5D=7c385677-0e42-49f1-9d53-6dda46708a1d').to_return do |request|
                  {
                    status: 200,
                    body: {
                      results: [{
                        id: '4253bed2-62f8-463a-aef7-68c969705b0f',
                        text: 'produit 1',
                        record: {
                          id: '4253bed2-62f8-463a-aef7-68c969705b0f',
                        },
                      }]
                    }.to_json,
                  }
                end
              end

              mount do
                dynamic_form = Dynamic::Form.new(
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Commande',
                  mode: 'input',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Commande',
                      root_klass_name: 'Commande',
                      method_names: [],
                      attribute_name: 'vente',
                      normalized_input_prefix: 'commande@0',
                      type: 'Association::BelongsTo',
                      default_value_record: {
                        id: '7c385677-0e42-49f1-9d53-6dda46708a1d', # <--
                        type: 'Vente',
                      },
                    },
                    {
                      id: 'a0887879-9d01-4765-939b-b48a625d6142',
                      klass_name: 'Commande',
                      root_klass_name: 'Commande',
                      method_names: [],
                      attribute_name: 'produit',
                      normalized_input_prefix: 'commande@0',
                      type: 'Association::BelongsTo',
                      autocomplete_filters: {vente: {variable: 'vente'}} # <--
                    },
                  ],
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should filter autocomplete result' do
              find('select[name="commande[produit]"]+.ts-wrapper').click
              expect(page).to have_content('produit 1')
            end

            it 'with longer path should filter autocomplete result' do
              mount do
                dynamic_form = Dynamic::Form.new(
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Commande',
                  mode: 'input',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Commande',
                      root_klass_name: 'Commande',
                      method_names: [],
                      attribute_name: 'vente',
                      normalized_input_prefix: 'commande@0',
                      type: 'Association::BelongsTo',
                      default_value_record: {
                        id: '7c385677-0e42-49f1-9d53-6dda46708a1d', # <--
                        type: 'Vente',
                      },
                    },
                    {
                      id: 'a0887879-9d01-4765-939b-b48a625d6142',
                      klass_name: 'Commande',
                      root_klass_name: 'Commande',
                      method_names: [],
                      attribute_name: 'produit',
                      normalized_input_prefix: 'commande@0.test@0.test@0.test@0', # <-----
                      type: 'Association::BelongsTo',
                      autocomplete_filters: {vente: {variable: 'vente'}}
                    },
                  ],
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end

              find('select[name="commande[produit]"]+.ts-wrapper').click
              expect(page).to have_content('produit 1')
            end
          end

          context 'autocomplete with a variable from an has_many' do
            before(:each) do
              page_exec do
                class Commande < HyperResource::Base
                  def self.api_path
                    '/commandes'
                  end
                  has_many :ventes, class_name: 'Vente'
                  belongs_to :produit, class_name: 'Produit' # todo same test with has_many
                end
                class Produit < HyperResource::Base
                  def self.api_path
                    '/produits'
                  end
                  belongs_to :vente, class_name: 'Vente'
                end
                class Vente < HyperResource::Base
                  def self.api_path
                    '/ventes'
                  end
                end

                stub_request(:get, '/produits.json?filters=(and%3A!((vente%3A(variable%3Aventes))))&owner_klass_name=Commande&association_name=produit&term=&select2=true&variables%5Bventes%5D%5B%5D=7c385677-0e42-49f1-9d53-6dda46708a1d').to_return do |request|
                  {
                    status: 200,
                    body: {
                      results: [{
                        id: '4253bed2-62f8-463a-aef7-68c969705b0f',
                        text: 'produit 1',
                        record: {
                          id: '4253bed2-62f8-463a-aef7-68c969705b0f',
                        },
                      }]
                    }.to_json,
                  }
                end
              end

              mount do
                dynamic_form = Dynamic::Form.new(
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Commande',
                  mode: 'input',
                  elements: [
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      klass_name: 'Commande',
                      root_klass_name: 'Commande',
                      method_names: [],
                      attribute_name: 'ventes',
                      normalized_input_prefix: 'commande@0',
                      type: 'Association::HasMany',
                      default_value_records: [{
                        id: '7c385677-0e42-49f1-9d53-6dda46708a1d', # <--
                        type: 'Vente',
                      }],
                    },
                    {
                      id: 'a0887879-9d01-4765-939b-b48a625d6142',
                      klass_name: 'Commande',
                      root_klass_name: 'Commande',
                      method_names: [],
                      attribute_name: 'produit',
                      normalized_input_prefix: 'commande@0',
                      type: 'Association::BelongsTo',
                      autocomplete_filters: {vente: {variable: 'ventes'}} # <--
                    },
                  ],
                )
                dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
                Form(dynamic_form: dynamic_form)
              end
            end

            it 'should filter autocomplete result' do
              find('select[name="commande[produit]"]+.ts-wrapper').click
              expect(page).to have_content('produit 1')
            end

          end
        end
      end
    end
  end
end
