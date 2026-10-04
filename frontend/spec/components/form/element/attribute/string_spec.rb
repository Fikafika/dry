describe 'Form::Element::Attribute::String', type: :system do
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
      before(:each) do
        mount do
          Form(record: Record.new(attr: 'titi')) do
            Form::Element::Attribute::String(attribute_name: 'attr')
          end
        end
      end

      it 'should have attribute value' do
        expect(find('input[name="record[attr]"]').value).to eq 'titi'
      end

      it 'should init submission params' do
        expect(page_eval{
          Form.current.submission.params.dig('record', 'attr').to_s
        }).to eq 'titi'
      end

      describe 'user fill input' do
        before(:each) do
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::String(attribute_name: 'attr')
            end
          end

          find('input[name="record[attr]"]').set('toto')
        end

        it 'should fill submission params' do
          expect(page_eval{
            Form.current.submission.params.dig('record', 'attr').to_s
          }).to eq 'toto'
        end

      end

    end

    context 'editor = tel' do
      before(:each) do
        mount do
          Form(record: Record.new(attr: '')) do
            Form::Element::Attribute::String(attribute_name: 'attr', editor: 'tel')
          end
        end
      end

      it 'should return international number ' do
        find('input[name="record[attr]"]').set('+33687456987')
        expect(find('input[name="record[attr]"]').value).to eq '+33687456987'
      end

      it 'should return corect international number based on number starting with 0 and without prefix' do
        find('input[name="record[attr]"]').set('0687456987')
        expect(find('input[name="record[attr]"]').value).to eq '+33687456987'
      end

      it 'should have a openable dropdown menu with countries after click on button' do
        expect(find('button[name="btn_dropdown_countries"]')['aria-expanded']).to eq('false')
        find('button[name="btn_dropdown_countries"]').click
        expect(find('button[name="btn_dropdown_countries"]')['aria-expanded']).to eq('true')
      end

      it 'should return prefix of a choosen country' do
        find('button[name="btn_dropdown_countries"]').click
        find('button[name="France"]').click
        expect(find('input[name="record[attr]"]').value).to eq '+33'
      end

      it 'should replace prefix of the number in input_tel based on chosen country ' do
        find('input[name="record[attr]"]').set('+33687456987')
        find('button[name="btn_dropdown_countries"]').click
        find('button[name="Aruba"]').click
        find('input[name="record[attr]"]').set('+297687456987')
      end

    end

    context 'editor = autocomplete' do
      context 'without api_data' do

        context 'assign existing record' do
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
                has_many :nesteds, class_name: 'Nested'
                belongs_to :nested, class_name: 'Nested'
              end
              class Record < HyperResource::Base
                def self.api_path
                  '/records'
                end
                has_many :nesteds, class_name: 'Nested'
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
                    autocomplete_filters: {name: {contains: {variable: 'attr'}}}
                  }, {
                    id: 2,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'name',
                    editor: 'autocomplete',
                    parent_id: 1,
                    type: 'Attribute::String',
                  }, {
                    id: 3,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'attr',
                    parent_id: 1,
                    type: 'Attribute::String',
                  }, {
                    id: 4,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'nesteds',
                    mode: 'nested_form',
                    parent_id: 1,
                    type: 'Association::HasMany',
                  }, {
                    id: 5,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds', 'nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0.nesteds@0',
                    attribute_name: 'name',
                    editor: 'autocomplete',
                    parent_id: 4,
                    type: 'Attribute::String',
                  }, {
                    id: 6,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds', 'nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0.nesteds@0',
                    attribute_name: 'attr',
                    requirement: 'mandatory', # <-
                    parent_id: 4,
                    type: 'Attribute::String',
                  },
                  {
                    id: 7,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'nested',
                    requirement: 'mandatory', # <-
                    parent_id: 1,
                    type: 'Association::BelongsTo',
                  },
                ],
              )
              dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
              Form(dynamic_form: dynamic_form)
            end
          end

          it 'should display an autocomplete when click on input' do
            find('input[name="record.nesteds@0[name]"]').click
            expect(page).to have_css('.dropdown-menu')
            expect(page).to have_content('nested 1')
            expect(page).to have_content('nested 2')
          end

          it 'should fill fields when click in items of autocomplete' do
            find('input[name="record.nesteds@0[name]"]').click # open autocomplete
            expect(page).to have_css('.dropdown-menu') # wait autocomplete results
            find('.dropdown-item', text: 'nested 1').click # click on item
            find_field('record.nesteds@0[attr]', with: 'A', disabled: true) # should fill attr and disable it
            find_field('record.nesteds@0[name]', disabled: false) # but not disable autocomplete field

            find_field('record.nesteds@0.nesteds@0[attr]', with: 'AA', disabled: true) # should disable associated attr

            find_field('record.nesteds@0[nested]', disabled: true, visible: false) # should disable associated association (visible false due to select2)
            expect(page).to have_css('.ts-control .item', text: 'nested 1 nested') # select2 should display name of belongs_to

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record@0.nesteds@0' => {
                  'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  'name' => 'nested 1',
                  'attr' => 'A',
                },
                'record@0.nesteds@0.nesteds@0' => {
                  'id' => 'b5d90084-8313-4447-9fd7-f0e3716292d9',
                  'name' => 'nested 1 nesteds 1',
                  'attr' => 'AA',
                },
               'record@0.nesteds@0.nested@0' => {
                  'id'=> '76b0f801-4d38-4333-891b-1c90dc6e1e68',
                  'name' => "nested 1 nested", # why present ?
                },
              }
            )
          end

          it 'should not disable associated fields that are both empty and mandatory' do # because it prevents user to fill it
            find('input[name="record.nesteds@0[name]"]').click # open autocomplete
            expect(page).to have_css('.dropdown-menu') # wait autocomplete results
            find('.dropdown-item', text: 'nested 2').click # click on item
            find_field('record.nesteds@0[attr]', with: 'B', disabled: true) # should fill attr and disable it
            find_field('record.nesteds@0[name]', disabled: false) # but not disable autocomplete field

            expect(page_eval do
              Form.current.submission.original_values.has_key?(['record', 0, 'nesteds', 0, 'nesteds', 0, 'attr']).to_n
            end).to be false # it should be write_from_db

            find_field('record.nesteds@0.nesteds@0[attr]', with: '', disabled: false) # should disable associated attr because empty and mandatory
            find_field('record.nesteds@0[nested]', disabled: false, visible: false) # should not disable associated association because empty and mandatory

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record@0.nesteds@0' => {
                  'id' => '2caf771d-7a92-40bb-908c-3c835e054367',
                  'name' => 'nested 2',
                  'attr' => 'B',
                  'nested' => nil
                },
                'record@0.nesteds@0.nesteds@0' => {
                  'id' => '6a3d8848-1fea-432d-906c-2f14308e1710',
                  'name' => 'nested 2 nesteds 1',
                  'attr' => nil,
                },
              }
            )

            find_field('record.nesteds@0.nesteds@0[attr]').set('a') # change should

            expect(page_eval do
              Form.current.submission.original_values.has_key?(['record', 0, 'nesteds', 0, 'nesteds', 0, 'attr']).to_n
            end).to be true # it should be write_from_user

            expect(page_eval do
              Form.current.submission.was(['record', 0, 'nesteds', 0, 'nesteds', 0, 'attr']).blank?.to_n
            end).to be true # it should be write_from_user

            find_field('record.nesteds@0.nesteds@0[attr]', with: 'a', disabled: false) # should not disable
          end

          context 'already associated' do # TODO init with a submission that contains already associated records
            before(:each) do
              find('input[name="record.nesteds@0[name]"]').click # open autocomplete
              expect(page).to have_css('.dropdown-menu') # wait autocomplete results
              find('.dropdown-item', text: 'nested 1').click # click on item
              find_field('record.nesteds@0[attr]', with: 'A', disabled: true) # should fill attr and disable it
            end

            it 'should deassociate when change autocomplete input' do
              find('input[name="record.nesteds@0[name]"]').native.send_keys(:backspace)
              find_field('record.nesteds@0[attr]', with: '', disabled: false) # clear associated fields and reenable them
              expect(
                page_eval do
                  Form.current.submission.params.to_n
                end
              ).to eq(
                {
                  'record@0.nesteds@0' => {
                    'name' => 'nested ', # "nested 1" + backspace
                    'attr' => nil,
                  }
                }
              )
            end
          end

        end

        context 'two autocompletes' do
          before(:each) do
            page_exec do
              class Contact < HyperResource::Base
                def self.api_path
                  '/contacts'
                end
              end
              stub_request(:get, /\/contacts\.json/).to_return do |request|
                {
                  status: 200,
                  body: {
                    results: [{
                      id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      text: 'Iris Boulanger',
                    }, {
                      id: '2caf771d-7a92-40bb-908c-3c835e054367',
                      text: 'Quentin Meunier',
                    }]
                  }.to_json,
                }
              end
              stub_request(:get, /\/contacts\/17ad7795e-9899-47a9-a38f-6c1ead61991b\.json/).to_return do |request|
                {
                  status: 200,
                  body: {
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    first_name: 'Iris',
                    last_name: 'Boulanger',
                    birth_date: '2010-01-01',
                  }.to_json,
                }
              end

              stub_request(:get, /\/contacts\/2caf771d-7a92-40bb-908c-3c835e054367\.json/).to_return do |request|
                {
                  status: 200,
                  body: {
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    first_name: 'Quentin',
                    last_name: 'Meunier',
                    birth_date: '2012-12-12',
                  }.to_json,
                }
              end
            end

            mount do
              dynamic_form = Dynamic::Form.new(
                id: 1,
                klass_name: 'Contact',
                elements: [
                  {
                    id: 1,
                    klass_name: 'Contact',
                    root_klass_name: 'Contact',
                    normalized_input_prefix: 'contact@0',
                    attribute_name: 'first_name',
                    editor: 'autocomplete',
                    type: 'Attribute::String',
                  }, {
                    id: 2,
                    klass_name: 'Contact',
                    root_klass_name: 'Contact',
                    normalized_input_prefix: 'contact@0',
                    attribute_name: 'last_name',
                    editor: 'autocomplete',
                    type: 'Attribute::String',
                  }, {
                    id: 3,
                    klass_name: 'Contact',
                    root_klass_name: 'Contact',
                    normalized_input_prefix: 'contact@0',
                    attribute_name: 'birth_date',
                    type: 'Attribute::Date',
                  }
                ]
              )
              dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
              Form(dynamic_form: dynamic_form)
            end
          end

          context 'select item in first autocomplete' do
            before(:each) do
              find_field('contact[first_name]').click # open autocomplete
              expect(page).to have_css('.dropdown-menu') # wait autocomplete results
              find('.dropdown-item', text: 'Iris Boulanger').click # click on item
              find_field('contact[birth_date]', with: '2010-01-01', disabled: true) # should disabled non autocomplete fields
            end

            it 'change text in second autocomplete should deassociate' do
              find_field('contact[last_name]').native.send_keys(:backspace) # change autocomplete field
              find_field('contact[birth_date]', with: '') # should clean non autocomplete fields
            end
          end

        end

        context 'several nested records' do
          before(:each) do
            page_exec do
              class Contact < HyperResource::Base
                def self.api_path
                  '/contacts'
                end
                has_many :emails, class_name: 'Email'
              end
              class Email < HyperResource::Base
                def self.api_path
                  '/emails'
                end
              end
              stub_request(:get, /\/contacts\.json/).to_return do |request|
                {
                  status: 200,
                  body: {
                    results: [{
                      id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                      text: 'Iris Boulanger',
                    }, {
                      id: '2caf771d-7a92-40bb-908c-3c835e054367',
                      text: 'Quentin Meunier',
                    }]
                  }.to_json,
                }
              end
              stub_request(:get, /\/contacts\/17ad7795e-9899-47a9-a38f-6c1ead61991b\.json/).to_return do |request|
                {
                  status: 200,
                  body: {
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    first_name: 'Iris',
                    last_name: 'Boulanger',
                    emails: [
                      {address: 'iris@boulanger.fr'},
                      {address: 'iris-boulanger@gmail.com'},
                    ],
                  }.to_json,
                }
              end
              stub_request(:get, /\/contacts\/2caf771d-7a92-40bb-908c-3c835e054367\.json/).to_return do |request|
                {
                  status: 200,
                  body: {
                    id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                    first_name: 'Quentin',
                    last_name: 'Meunier',
                    emails: [
                      {address: 'quentin@meunier.fr'}
                    ],
                  }.to_json,
                }
              end
            end

            mount do
              dynamic_form = Dynamic::Form.new(
                id: 1,
                klass_name: 'Contact',
                elements: [
                  {
                    id: 1,
                    klass_name: 'Contact',
                    root_klass_name: 'Contact',
                    normalized_input_prefix: 'contact@0',
                    attribute_name: 'first_name',
                    editor: 'autocomplete',
                    type: 'Attribute::String',
                  }, {
                    id: 2,
                    klass_name: 'Contact',
                    root_klass_name: 'Contact',
                    normalized_input_prefix: 'contact@0',
                    attribute_name: 'last_name',
                    editor: 'autocomplete',
                    type: 'Attribute::String',
                  }, {
                    id: 3,
                    klass_name: 'Contact',
                    root_klass_name: 'Contact',
                    normalized_input_prefix: 'contact@0',
                    attribute_name: 'emails',
                    method_names: [],
                    mode: 'nested_form',
                    type: 'Association::HasMany',
                  }, {
                    id: 4,
                    klass_name: 'Email',
                    root_klass_name: 'Contact',
                    method_names: ['emails'],
                    normalized_input_prefix: 'contact@0.emails@0',
                    attribute_name: 'address',
                    parent_id: 3,
                    type: 'Attribute::String',
                  }
                ]
              )
              dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
              Form(dynamic_form: dynamic_form)
            end

            find_field('contact[first_name]').click # open autocomplete
            expect(page).to have_css('.dropdown-menu') # wait autocomplete results
            find('.dropdown-item', text: 'Iris Boulanger').click # click on item
            find_field('contact.emails@0[address]', with: 'iris@boulanger.fr', disabled: true) # should disabled non autocomplete fields
            find_field('contact.emails@1[address]', with: 'iris-boulanger@gmail.com', disabled: true) # should disabled non autocomplete fields
          end

          it 'select another item should remove all nesteds and fill with new ones' do
            find_field('contact[first_name]').click
            find('.dropdown-item', text: 'Quentin Meunier').click # click on item
            find_field('contact.emails@0[address]', with: 'quentin@meunier.fr', disabled: true) # should disabled non autocomplete fields
            expect(page).to_not have_css('input[name="contact.emails@1[address]"]')
          end
        end

        context 'ancestors autocomplete_filters' do
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
                    autocomplete_filters: {name: {contains: {variable: 'attr'}}}
                  }, {
                    id: 2,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'name',
                    editor: 'autocomplete',
                    parent_id: 1,
                    type: 'Attribute::String',
                  }, {
                    id: 3,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'attr',
                    editor: 'autocomplete',
                    parent_id: 1,
                    type: 'Attribute::String',
                  },{
                    id: 4,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0',
                    attribute_name: 'nesteds',
                    mode: 'nested_form',
                    parent_id: 1,
                    min: 1,
                    type: 'Association::HasMany',
                  },{
                    id: 5,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds', 'nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0.nesteds@0',
                    attribute_name: 'name',
                    editor: 'autocomplete',
                    parent_id: 4,
                    type: 'Attribute::String',
                  },{
                    id: 6,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nesteds', 'nesteds'],
                    normalized_input_prefix: 'record@0.nesteds@0.nesteds@0',
                    attribute_name: 'attr',
                    editor: 'autocomplete',
                    parent_id: 4,
                    type: 'Attribute::String',
                  },
                ],
              )
              dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
              Form(dynamic_form: dynamic_form)
            end
          end

          it 'should apply ancestors filters to the child form' do
            find('input[name="record.nesteds@0[name]"]').click
            request_url_params = page_eval('WebMock::RequestRegistry.instance.to_s').split(' ')[1]
            expect(request_url_params).to eq('/nesteds.json?select2=true&filters=(and%3A!((name%3A(contains%3A(variable%3Aattr)))))&variables%5Battr%5D=')
          end

          it 'should apply ancestors filters to the second child' do
            find('input[name="record.nesteds@0[attr]"]').click
            request_url_params = page_eval('WebMock::RequestRegistry.instance.to_s').split(' ')[1]
            expect(request_url_params).to eq('/nesteds.json?select2=true&filters=(and%3A!((name%3A(contains%3A(variable%3Aattr)))))&variables%5Battr%5D=')
          end

          it 'should apply ancestors filters to the second child' do
            find('input[name="record.nesteds@0.nesteds@0[attr]"]').click
            request_url_params = page_eval('WebMock::RequestRegistry.instance.to_s').split(' ')[1]
            expect(request_url_params).to eq('/nesteds.json?select2=true&filters=(and%3A!((nested_owner.name%3A(contains%3A(variable%3Aattr)))))&variables%5Battr%5D=')
          end
        end

        context 'has_many tom select' do
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
                has_many :nesteds, class_name: 'Nested'
                belongs_to :nested, class_name: 'Nested'
              end
              class Record < HyperResource::Base
                def self.api_path
                  '/records'
                end
                belongs_to :nested, class_name: 'Nested'
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
                    attribute_name: 'nested',
                    normalized_input_prefix: 'record@0',
                    mode: 'nested_form',
                    min: 1,
                    type: 'Association::BelongsTo',
                  }, {
                    id: 2,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nested'],
                    normalized_input_prefix: 'record@0.nested@0',
                    attribute_name: 'name',
                    editor: 'autocomplete',
                    parent_id: 1,
                    type: 'Attribute::String',
                  }, {
                    id: 3,
                    klass_name: 'Nested',
                    root_klass_name: 'Record',
                    method_names: ['nested'],
                    normalized_input_prefix: 'record@0.nested@0',
                    attribute_name: 'nesteds',
                    parent_id: 1,
                    type: 'Association::HasMany',
                  },
                ],
              )
              dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
              Form(dynamic_form: dynamic_form)
            end
          end

          it 'should display an autocomplete when click on input' do
            find('input[name="record.nested@0[name]"]').click
            expect(page).to have_css('.dropdown-menu')
            expect(page).to have_content('nested 1')
            expect(page).to have_content('nested 2')
          end

          it 'should fill fields when click in items of autocomplete' do
            find('input[name="record.nested@0[name]"]').click # open autocomplete
            expect(page).to have_css('.dropdown-menu') # wait autocomplete results
            find('.dropdown-item', text: 'nested 1').click # click on item
            expect(page).to have_css('.ts-control .item', text: 'nested 1 nested') # select2 should display name of belongs_to
            find_field('record.nested@0[nesteds][]', disabled: true, visible: false) # should fill it and disable it

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'record@0.nested@0' => {
                  'id' => '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  'name' => 'nested 1', # TODO should not be present
                  'attr' => 'A', # TODO should not be present
                },
                'record@0.nested@0.nested@0' => { # TODO should not be present
                  'id' => '76b0f801-4d38-4333-891b-1c90dc6e1e68',
                  'name' =>'nested 1 nested'
                },
                'record@0.nested@0.nesteds@0' => {
                  'id' => 'b5d90084-8313-4447-9fd7-f0e3716292d9',
                  'name' => 'nested 1 nesteds 1', # TODO should not be present
                  'attr' => 'AA', # TODO should not be present
                },
              }
            )
          end

        end
      end

      context 'with api_data' do
        before(:each) do
          page_exec do
            class Address < HyperResource::Base
              def self.api_path
                '/addresses'
              end

              def self.api_data
                {
                  street: {
                    url: '/search_address',
                    term_param: 'term',
                    fill_not_in_form_fields: true, # ??
                    process_results: ::Dynamic::Api::AddressSearchEngine::Feature::Address.process_results,
                    convert_selected_item: ::Dynamic::Api::AddressSearchEngine::Feature::Address.convert_selected_item({
                      'street' => 'street',
                      'street2' => 'second_street',
                      'zip_code' => 'zip_code',
                      'city' => 'city',
                      'country' => 'country',
                    }),
                  }
                }
              end
            end

            stub_request(:get, /search_address/).to_return do |request|
              {
                status: 200,
                body: [
                  {
                    label: '1, rue du haut, 59000, Lille, France',
                    value: {
                      street: '1, rue du haut',
                      street2: 'bat. 1',
                      zip_code: '59000',
                      city: 'Lille',
                      country: 'France',
                    },
                  },
                  {
                    label: '99, rue du bas, 13000, Marseille, France',
                    value: {
                      street: '99, rue du bas',
                      zip_code: '13000',
                      city: 'Marseille',
                      country: 'France',
                    },
                  }
                ].to_json,
              }
            end
          end
          mount do
            dynamic_form = Dynamic::Form.new(
              id: 1,
              klass_name: 'Address',
              elements: [
                {
                  id: 1,
                  klass_name: 'Address',
                  root_klass_name: 'Address',
                  method_names: [],
                  attribute_name: 'street',
                  normalized_input_prefix: 'address@0',
                  editor: 'autocomplete',
                  type: 'Attribute::String',
                }, {
                  id: 2,
                  klass_name: 'Address',
                  root_klass_name: 'Address',
                  method_names: [],
                  normalized_input_prefix: 'address@0',
                  attribute_name: 'city',
                  type: 'Attribute::String',
                }
              ],
            )
            dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
            Form(dynamic_form: dynamic_form)
          end
        end

        it 'should fill associated fields when click in autocomplete' do
          find('input[name="address[street]"]').click # open autocomplete
          expect(page).to have_css('.dropdown-menu') # wait autocomplete results
          find('.dropdown-item', text: '1, rue du haut, 59000, Lille, France').click # click on item
          find_field('address[street]', with: '1, rue du haut') # should fill street (and not disable it)
          find_field('address[city]', with: 'Lille') # should fill city (and not disable it)
          expect(
            page_eval do
              Form.current.submission.params.to_n
            end
          ).to eq(
            {
              'address@0' => {
                'street' => '1, rue du haut',
                'second_street' => 'bat. 1',
                'zip_code' => '59000',
                'city' => 'Lille',
                'country' => 'France',
              }
            }
          )
        end

        context 'already filled' do
          before(:each) do
            find('input[name="address[street]"]').click # open autocomplete
            expect(page).to have_css('.dropdown-menu') # wait autocomplete results
            find('.dropdown-item', text: '1, rue du haut, 59000, Lille, France').click # click on item
            page_exec do
              ::Element.find('input[name="address[street]"]').blur
            end
          end

          it 'should replace associated fields when click in autocomplete' do
            find('input[name="address[street]"]').click # open autocomplete
            expect(page).to have_css('.dropdown-menu') # wait autocomplete results
            find('.dropdown-item', text: '99, rue du bas, 13000, Marseille, France').click # click on item

            expect(
              page_eval do
                Form.current.submission.params.to_n
              end
            ).to eq(
              {
                'address@0' => {
                  'street' => '99, rue du bas',
                  'zip_code' => '13000',
                  'second_street' => nil,
                  'city' => 'Marseille',
                  'country' => 'France',
                }
              }
            )
          end

        end

      end

    end

  end

  context 'mode = edit in place' do
    context 'render attribute value with specific html tag depending if it has protocols or not' do
      before(:each) do
        page_exec do
          class Email < HyperResource::Base
            def self.name_attribute
              'address'
            end

            #enum protocols: {http: 0, mailto: 1, tel: 2, sms: 3}
            def self.protocols_for_attributes
              {tag_link: ['http']}
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
                klass_name: 'Email',
                root_klass_name: 'Email',
                method_names: [],
                attribute_name: 'address',
                normalized_input_prefix: 'email@0',
                type: 'Attribute::String',
              },
              {
                id: 1,
                mode: 'edit_in_place',
                klass_name: 'Email',
                root_klass_name: 'Email',
                method_names: [],
                attribute_name: 'tag_link',
                normalized_input_prefix: 'email@0',
                type: 'Attribute::String',
              },
              {
                id: 1,
                mode: 'edit_in_place',
                klass_name: 'Email',
                root_klass_name: 'Email',
                method_names: [],
                attribute_name: 'status',
                normalized_input_prefix: 'email@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'email@0': {
                address: 'david@kosmo.fr',
                status: 'working',
                tag_link: 'www.verygreatlink.fr',
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'renders the tag_link value on a tag A with href value equal to tag_link if tag_link has protocols http' do
        expect(page).to have_css('a[href="www.verygreatlink.fr"]', text: 'www.verygreatlink.fr', count: 1)
      end

      describe 'when the attribute has not protocols' do
        it 'renders the address value on tag A with href link redirect to edit record if Email.name_attribute & attribute_name is the same' do
          expect(page).to have_css('a[data-open-panel="right"]', text: 'david@kosmo.fr', count: 1)
          expect(find('a[data-open-panel="right"]')['href']).to eq "#{Capybara.app_host}/crm/object/table/emails//edit"
        end

        it 'It renders the status value without the A tag if the attribute_name & Email.name_attribute is different' do
          expect(page.all('a').map(&:text)).not_to include('working')
          expect(page.all('span').map(&:text)).to include('working')
        end
      end

    end

    describe 'when the attribute has protocol and the Email.name_attribute & attribute_name is the same' do
      before(:each) do
        page_exec do
          class Email < HyperResource::Base
            def self.name_attribute
              'address'
            end

            #enum protocols: {http: 0, mailto: 1, tel: 2, sms: 3}
            def self.protocols_for_attributes
              {address: ['mailto']}
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
                klass_name: 'Email',
                root_klass_name: 'Email',
                method_names: [],
                attribute_name: 'address',
                normalized_input_prefix: 'email@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'email@0': {
                address: 'teste2e@gmail.com',
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should render address value in tag A with href using the protocols' do
        expect(page).to have_css('a[href="mailto:teste2e@gmail.com"]', text: 'teste2e@gmail.com', count: 1)
      end
    end

    context 'requirement = optional' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 1,
                mode: 'edit_in_place',
                requirement: 'optional',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'attr',
                normalized_input_prefix: 'record@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                id: 1,
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
        page_exec do
          stub_request(:patch, "/records/1.json").to_return do |request|
            {
              status: 200,
              body: {
                id: 1,
                attr: 'A'
              }.to_json,
            }
          end
        end
      end

      it 'should submit' do
        find('.form-control').click
        expect(page).to have_selector('input[type=text][name="record[attr]"]')
        find('input[type=text][name="record[attr]"]').set('A')
        page_exec do
          ::Element['input[type=text][name="record[attr]"]'].blur
        end
        expect(page).to have_selector('.fa-check')
      end
    end

    context 'requirement = mandatory' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 1,
                mode: 'edit_in_place',
                requirement: 'mandatory',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'attr',
                normalized_input_prefix: 'record@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                id: 1,
                attr: 'A',
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'submit should fail if value is not present' do
        find('.form-control').click
        expect(page).to have_selector('input[type=text][name="record[attr]"]')
        find('input[type=text][name="record[attr]"]').send_keys(:backspace, :enter)
        expect(page).to have_selector('.fa-times')
      end
    end

  end

  # qrcode ------------------------------------------------------------------------

  context 'editor = qrcode' do
    context 'input_qrcode' do
      before(:each) do
        mount do
          Form(record: Record.new(attr: 'www.google.com')) do
            Form::Element::Attribute::String(attribute_name: 'attr')
          end
        end
      end

      it 'should have attribute value' do
        expect(find('input[name="record[attr]"]').value).to eq 'www.google.com'
      end

      it 'should init submission params' do
        expect(page_eval{
          Form.current.submission.params.dig('record', 'attr').to_s
        }).to eq 'www.google.com'
      end

    end

    context 'form.mode = edit_in_place' do
      before(:each) do
        mount do
          dynamic_form = Dynamic::Form.new(
            id: 1,
            klass_name: 'Record',
            mode: 'edit_in_place',
            elements: [
              {
                id: 1,
                editor: 'qrcode',
                mode: 'edit_in_place',
                klass_name: 'Record',
                root_klass_name: 'Record',
                method_names: [],
                attribute_name: 'attr',
                normalized_input_prefix: 'record@0',
                type: 'Attribute::String',
              },
            ],
            serialized_record_for_input_prefix: {
              'record@0': {
                attr: 'www.google.com'
              },
            },
          )
          dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
          Form(dynamic_form: dynamic_form)
        end
      end

      it 'should display a qrcode' do
        expect(page).to have_css('.qr-code')
      end

      it 'should display an input string(url) when clicked on qrcode' do
        find('.form-control').click
        expect(page).to have_selector('input[type=text]')
        expect(find('input[name="record[attr]"]').value).to eq 'www.google.com'
      end

      it 'should change(src) and show a qrcode when string(url) is updated' do
        old_src = find('.qr-code')['src']
        find('.form-control').click
        find('input[name="record[attr]"]').set("www.uneek.com\n")
        new_src = find('.qr-code')['src']
        expect(old_src).not_to eq(new_src)
      end
    end
  end

  describe 'enable_after_user_interaction' do
    before(:each) do
      mount do
        Form(record: Record.new(attr: 'titi'), enable_after_user_interaction: true) do
          Form::Element::Attribute::String(attribute_name: 'attr')
        end
      end
    end

    it 'should have attribute value' do
      expect(find('input[name="record[attr]"]').value).to eq 'titi'
    end

    it 'should not be enabled' do
      expect(page_eval{
        Form.current.enabled?
      }).to eq false
    end

    describe 'user fill input' do
      before(:each) do
        mount do
          Form(record: Record.new, enable_after_user_interaction: true) do
            Form::Element::Attribute::String(attribute_name: 'attr')
          end
        end

        find('input[name="record[attr]"]').set('toto')
      end

      it 'should be enabled' do
        expect(page_eval{
          Form.current.enabled?
        }).to eq true
      end

    end
  end

end
