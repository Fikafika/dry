describe 'Form', type: :system do
  it 'empty form should have empty submission params' do
    mount do
      Form() do
      end
    end

    expect(page_eval{
      Form.current.submission.params.empty?
    }).to eq true
  end

  describe 'submit' do

    context 'record' do
      before(:each) do
        page_exec do
          class Record < HyperResource::Base
            def self.api_path; '/records'; end
            attribute :name
          end
        end
      end

      context 'error' do
        before(:each) do
          page_exec do
            stub_request(:post, /records/).to_return do |request|
              {
                status: 422,
                body: {
                  name: [{ error: 'blank' }]
                }.to_json,
              }
            end
          end
          mount do
            Form(record: Record.new) do
              Form::Element::Attribute::String(attribute_name: 'name')
              DIV(style: {height: '5000px'}) do
              end
              Form::Footer()
            end
          end
        end

        it 'should scroll to element with error' do
          find('input[name="record[name]"]').set(' ')
          find('.btn-primary').click
          expect(page).to have_css('.is-invalid')
          sleep 1 # wait scroll
          expect(page_eval{`$(window).scrollTop()`}).to eq 0
        end
      end
    end

    context 'dynamic_form' do

      it 'should clear record_for_input_prefix cache after success' do
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
          stub_request(:post, /\/submit\.json/).to_return do |request|
            $submitted = true
            {
              status: 200,
              body: {
                records: [{
                  id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
                  type: 'Record',
                }]
              }.to_json,
            }
          end
          stub_request(:get, /forms\/c3fe8d40\-4950\-49ce\-b107\-7dc181599aac\.json/).to_return do |request|
            response = {
              status: 200,
              body: {
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
                  {
                    id: '01990a8c-3d78-70a8-a147-3c4a115e7dd7',
                    type: 'Control::Navigation',
                  }
                ],
              },
            }

            unless $submitted
              response[:body][:serialized_record_for_input_prefix] = {
                'record@0': {
                  id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
                },
                'record@0.nesteds@0': {
                  id: '17ad7795e-9899-47a9-a38f-6c1ead61991b',
                  name: 'nested 1',
                },
              }
            else
              response[:body][:serialized_record_for_input_prefix] = {
                'record@0': {
                  id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
                },
              }
            end

            response[:body].to_json
            response
          end
        end
        mount do
          Form(
            dynamic_form_id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
            source_record_id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
            source_record_type: 'Record',
          ).on(:success) do
            Form.current.reset # like in Crm::Forms
            Element['.router-top-level'].add_class('success')
          end
        end

        # should display one item
        expect(page).to have_css('.ts-control .item', text: 'nested 1')

        find('.ts-control .item').find('.remove').click # click on x icon of item

        find('button', text: 'Enregistrer').click # submit

        find('.router-top-level.success') # wait success

        # should display not display removed item
        expect(page).to_not have_css('.ts-control .item', text: 'nested 1')
      end

      context 'with a final page' do

        it 'should display final page' do
          page_exec do
            class Record < HyperResource::Base
              def self.api_path
                '/records'
              end
            end
            stub_request(:post, /\/submit\.json/).to_return do |request|
              $submitted = true
              {
                status: 200,
                body: {
                  records: [{
                    id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
                    type: 'Record',
                  }]
                }.to_json,
              }
            end
            stub_request(:get, /forms\/c3fe8d40\-4950\-49ce\-b107\-7dc181599aac\.json/).to_return do |request|
              response = {
                status: 200,
                body: {
                  id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
                  klass_name: 'Record',
                  mode: 'input',
                  elements: [
                    {
                      id: '019970e1-f2c0-70d6-ac76-b1ca94f16aba',
                      type: 'Layout::Page',
                    },
                    {
                      id: 'f0e19422-c637-460b-aa49-b1819d9f300c',
                      parent_id: '019970e1-f2c0-70d6-ac76-b1ca94f16aba',
                      klass_name: 'Record',
                      root_klass_name: 'Record',
                      method_names: [],
                      attribute_name: 'attr',
                      normalized_input_prefix: 'record@0',
                      type: 'Attribute::String',
                    },
                    {
                      id: '01990a8c-3d78-70a8-a147-3c4a115e7dd7',
                      parent_id: '019970e1-f2c0-70d6-ac76-b1ca94f16aba',
                      type: 'Control::Navigation',
                    },
                    {
                      id: '019970e2-f878-745f-8997-6c2381c6cb29',
                      type: 'Layout::Page',
                    },
                    {
                      id: '01990a8c-3d78-70a8-a147-3c4a115e7dd7',
                      parent_id: '019970e2-f878-745f-8997-6c2381c6cb29',
                      text: 'final page',
                      type: 'Basic::Text',
                    },
                    {
                      id: '019970f7-efa8-77c2-a172-879b20059599',
                      parent_id: '019970e2-f878-745f-8997-6c2381c6cb29',
                      type: 'Control::Navigation',
                    },
                  ],
                },
              }

              unless $submitted
                response[:body][:serialized_record_for_input_prefix] = {
                  'record@0': {
                    id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
                    attr: 'A',
                  },
                }
              else
                response[:body][:serialized_record_for_input_prefix] = {
                  'record@0': {
                    id: '01990a99-b2c8-7105-8b49-740a5e8855e5',
                    attr: 'B',
                  },
                }
              end

              response[:body].to_json
              response
            end
          end
          mount do
            Form(
              dynamic_form_id: 'c3fe8d40-4950-49ce-b107-7dc181599aac',
              source_record_id: '01990a99-b2c8-7105-8b49-740a5e8855e5', # important because dynamic_form.stale! is called and this can cause bugs about page_count
              source_record_type: 'Record',
            ).on(:success) do
              Form.current.reset # like in Crm::Forms
              Element['.router-top-level'].add_class('success')
            end
          end

          expect(find('input[name="record[attr]"').value).to eq 'A'

          find('input[name="record[attr]"]').set('B')

          find('button', text: 'Enregistrer').click # submit

          find('.router-top-level.success') # wait success

          expect(page).to have_content('final page')

          find('button', text: 'Suivant').click

          expect(find('input[name="record[attr]"').value).to eq 'B'
        end

      end

    end

  end

  describe 'reset' do
    before(:each) do
      page_exec do
        class Record < HyperResource::Base
          def self.api_path; '/records'; end
          attribute :attr
          belongs_to :nested, class_name: 'Record'
        end
      end

    end

    it 'should reset inputs of associated records' do
      # why this test passes only if __hyperstack_component_rescue_hook is removed from form/element/base ?
      mount do
         $dynamic_form_attributes = {
          id: 1,
          klass_name: 'Record',
          mode: 'input',
          elements: [
            {
              id: 2,
              klass_name: 'Record',
              root_klass_name: 'Record',
              method_names: [],
              attribute_name: 'nested',
              normalized_input_prefix: 'record@0',
              mode: 'nested_form',
              type: 'Association::BelongsTo',
            }, {
              id: 3,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested'],
              normalized_input_prefix: 'record@0.nested@0',
              attribute_name: 'attr',
              parent_id: 2,
              type: 'Attribute::String',
            }
          ],
          serialized_record_for_input_prefix: {
          },
        }
        dynamic_form = Dynamic::Form.new($dynamic_form_attributes)
        dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
        Form(dynamic_form: dynamic_form)
      end

      find('input[name="record.nested@0[attr]"]').set('B')

      expect(find('input[name="record.nested@0[attr]"]').value).to eq 'B'

      page_exec{ Form.current.reset }

      expect(find('input[name="record.nested@0[attr]"]').value).to eq ''
    end

    it 'should reset values of inputs' do
      mount do
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
              attribute_name: 'attr',
              normalized_input_prefix: 'record@0',
              type: 'Attribute::String',
            },
            {
              id: 2,
              klass_name: 'Record',
              root_klass_name: 'Record',
              method_names: [],
              attribute_name: 'nested',
              normalized_input_prefix: 'record@0',
              mode: 'nested_form',
              type: 'Association::BelongsTo',
            }, {
              id: 3,
              klass_name: 'Nested',
              root_klass_name: 'Record',
              method_names: ['nested'],
              normalized_input_prefix: 'record@0.nested@0',
              attribute_name: 'attr',
              parent_id: 2,
              type: 'Attribute::String',
            }
          ],
          serialized_record_for_input_prefix: {
          },
        }
        dynamic_form = Dynamic::Form.new($dynamic_form_attributes)
        dynamic_form.status_code = 200 # dynamic_form.loaded? must be true
        Form(dynamic_form: dynamic_form)
      end


      find('input[name="record[attr]"').set('A')
      find('input[name="record.nested@0[attr]"]').set('B')

      expect(find('input[name="record[attr]"').value).to eq 'A'
      expect(find('input[name="record.nested@0[attr]"]').value).to eq 'B'

      page_exec{ Form.current.reset }

      expect(find('input[name="record[attr]"').value).to eq ''
      expect(find('input[name="record.nested@0[attr]"]').value).to eq ''
    end



  end

  describe 'params' do
    before(:each) do
      page_exec do
        class Record < HyperResource::Base
          def self.api_path; '/records'; end
          attribute :name
        end
      end
    end

    it 'should fill inputs' do
      mount do
        Form(record: Record.new(name: 'A'), params: {record: {name: 'B'}}) do
          Form::Element::Attribute::String(attribute_name: 'name')
        end
      end
      expect(find('input[name="record[name]"').value).to eq 'B'
      expect(page_eval{
        Form.current.submission.params == {record: {name: 'B'}}
      }).to eq true
    end

    context 'record and params changed' do
      before(:each) do
        page_exec do
          class ComponentWithForm < HyperComponent
            before_mount do
              @record = Record.new(name: 'A')
              @params = {record: {name: 'B'}}
            end

            render do
              Form(record: @record, params: @params) do
                Form::Element::Attribute::String(attribute_name: 'name')
              end
              BUTTON do
                'button'
              end.on(:click) do
                @record = Record.new(name: 'C')
                @params = {record: {name: 'D'}}
                mutate
              end
            end
          end
        end
        mount do
          ComponentWithForm()
        end
      end

      it 'should change inputs' do
        expect(find('input[name="record[name]"').value).to eq 'B'
        find('button').click
        expect(find('input[name="record[name]"').value).to eq 'D'
      end
    end
  end

  describe 'in external' do
    before(:each) do
      page_exec do
        class Record < HyperResource::Base
          def self.api_path; '/records'; end
          attribute :name
        end

        def render_form
          Form(record: (observe Record.find(1))) do
            if @res
              DIV(class: 'message-custom'){'Cust message'}
            end
          end.on(:loaded) do
            @res = true
            mutate
          end
        end
      end
    end

    context 'loaded' do
      before(:each) do
        page_exec do
          stub_request(:get, /records/).to_return do |request|
            {
              status: 200,
              body: {
                name: 'toto'
              }.to_json,
            }
          end
        end
        mount do
          render_form
        end
      end

      it 'should fire loaded event' do
        expect(page).to have_css('div.message-custom')
      end
    end

    context 'not loaded' do
      before(:each) do
        page_exec do
          stub_request(:get, /records/).to_return do |request|
            {
              status: 404,
            }
          end
        end
        mount do
          render_form
        end
      end

      it 'should not fire loaded event' do
        expect(page).to_not have_css('div.message-custom')
      end
    end

  end
end
