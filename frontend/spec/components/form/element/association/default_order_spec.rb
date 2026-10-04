describe 'Form::Element::Association::Base default order', type: :system do
  before(:each) do
    page_exec do
      class Nested < HyperResource::Base
        def self.api_path
          '/nesteds'
        end

        def self.name_attribute
          'name'
        end
      end
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
        belongs_to :nested, class_name: 'Nested'
      end
    end
  end

  def mount_radio_form
    mount do
      dynamic_form = Dynamic::Form.new(
        id: '019291a0-0000-7000-8000-000000000001',
        klass_name: 'Record',
        mode: 'input',
        elements: [
          {
            id: '019291a0-0000-7000-8000-000000000002',
            klass_name: 'Record',
            root_klass_name: 'Record',
            method_names: [],
            attribute_name: 'nested',
            mode: nil,
            editor: 'radio',
            normalized_input_prefix: 'record@0',
            type: 'Association::BelongsTo',
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

  context 'without default order on the association' do
    before(:each) do
      page_exec do
        stub_request(:get, '/nesteds.json?order%5Bname%5D=asc').to_return do |request|
          {
            status: 200,
            body: [
              {id: '019291a0-0000-7000-8000-00000000000a', name: 'nested 1'},
              {id: '019291a0-0000-7000-8000-00000000000b', name: 'nested 2'},
            ].to_json,
          }
        end
      end
      mount_radio_form
    end

    it 'should order the records by the name attribute' do
      expect(page).to have_css('input[type="radio"]', count: 2)
      expect(page).to have_content('nested 1')
    end
  end

  context 'with a default order on the association' do
    before(:each) do
      page_exec do
        Record.reflect_on_association('nested').define_singleton_method(:default_elasticsearch_order) do
          [['position', 'asc'], ['name', 'desc']]
        end
        stub_request(:get, '/nesteds.json?order%5Bposition%5D=asc&order%5Bname%5D=desc').to_return do |request|
          {
            status: 200,
            body: [
              {id: '019291a0-0000-7000-8000-00000000000a', name: 'nested 1'},
              {id: '019291a0-0000-7000-8000-00000000000b', name: 'nested 2'},
            ].to_json,
          }
        end
      end
      mount_radio_form
    end

    it 'should order the records with the default order of the association' do
      expect(page).to have_css('input[type="radio"]', count: 2)
      expect(page).to have_content('nested 1')
    end
  end

  context 'with a legacy flattened default order on the association' do
    before(:each) do
      page_exec do
        Record.reflect_on_association('nested').define_singleton_method(:default_elasticsearch_order) do
          ['position', 'desc']
        end
        stub_request(:get, '/nesteds.json?order%5Bposition%5D=desc').to_return do |request|
          {
            status: 200,
            body: [
              {id: '019291a0-0000-7000-8000-00000000000a', name: 'nested 1'},
            ].to_json,
          }
        end
      end
      mount_radio_form
    end

    it 'should read it as a single pair' do
      expect(page).to have_css('input[type="radio"]', count: 1)
      expect(page).to have_content('nested 1')
    end
  end

  context 'with only a sorting type on the form element' do
    before(:each) do
      page_exec do
        Record.reflect_on_association('nested').define_singleton_method(:default_elasticsearch_order) do
          [['position', 'asc']]
        end
        stub_request(:get, '/nesteds.json?order%5Bname%5D=desc').to_return do |request|
          {
            status: 200,
            body: [
              {id: '019291a0-0000-7000-8000-00000000000a', name: 'nested 1'},
            ].to_json,
          }
        end
      end
      mount do
        Form(record: Record.new) do
          Form::Element::Association::BelongsTo(
            attribute_name: 'nested',
            editor: 'radio',
            sorting_type: 'desc',
          )
        end
      end
    end

    it 'should keep ordering on the name attribute with that direction' do
      expect(page).to have_css('input[type="radio"]', count: 1)
      expect(page).to have_content('nested 1')
    end
  end

  context 'with a sorting attribute on the form element' do
    before(:each) do
      page_exec do
        Record.reflect_on_association('nested').define_singleton_method(:default_elasticsearch_order) do
          [['position', 'asc']]
        end
        stub_request(:get, '/nesteds.json?order%5Bname%5D=desc').to_return do |request|
          {
            status: 200,
            body: [
              {id: '019291a0-0000-7000-8000-00000000000a', name: 'nested 1'},
            ].to_json,
          }
        end
      end
      mount do
        Form(record: Record.new) do
          Form::Element::Association::BelongsTo(
            attribute_name: 'nested',
            editor: 'radio',
            sorting_attribute: 'name',
            sorting_type: 'desc',
          )
        end
      end
    end

    it 'should take precedence over the default order of the association' do
      expect(page).to have_css('input[type="radio"]', count: 1)
      expect(page).to have_content('nested 1')
    end
  end

end
