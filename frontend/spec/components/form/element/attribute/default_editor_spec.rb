describe 'Form::Element::Attribute editor defaulted from schema attribute format', type: :system do

  before(:each) do
    page_exec do
      class Record < HyperResource::Base
        def self.api_path
          '/records'
        end
      end
    end
  end

  it 'maps string formats to editors' do
    expect(
      page_eval do
        klass = Class.new
        klass.define_singleton_method(:attribute_format) do |attr|
          {
            'phone_number' => 'phone',
            'serial' => 'qrcode',
          }[attr]
        end

        component = Form::Element::Attribute::String.allocate
        component.define_singleton_method(:record_klass) { klass }

        ['phone_number', 'serial', 'other'].map do |attr|
          component.define_singleton_method(:attribute_name) { attr }
          component.default_editor
        end.to_n
      end
    ).to eq ['tel', 'qrcode', 'text']
  end

  it 'restricts the autocomplete editor to input mode' do
    expect(
      page_eval do
        klass = Class.new
        klass.define_singleton_method(:attribute_editor) do |attr|
          'autocomplete' if attr == 'city'
        end

        component = Form::Element::Attribute::String.allocate
        component.define_singleton_method(:record_klass) { klass }
        component.define_singleton_method(:attribute_name) { 'city' }

        ['input', 'edit_in_place', 'read_only'].map do |mode|
          component.define_singleton_method(:mode) { mode }
          component.default_editor
        end.to_n
      end
    ).to eq ['autocomplete', 'text', 'text']
  end

  it 'maps text formats to editors' do
    expect(
      page_eval do
        klass = Class.new
        klass.define_singleton_method(:attribute_format) do |attr|
          {
            'notes' => 'raw',
            'description' => 'rich',
          }[attr]
        end

        component = Form::Element::Attribute::Text.allocate
        component.define_singleton_method(:record_klass) { klass }

        ['notes', 'description', 'other'].map do |attr|
          component.define_singleton_method(:attribute_name) { attr }
          component.default_editor
        end.to_n
      end
    ).to eq ['textarea', 'tinymce', 'tinymce']
  end

  it 'falls back to the default editor when the klass has no attribute_format' do
    expect(
      page_eval do
        klass = Class.new

        string_component = Form::Element::Attribute::String.allocate
        string_component.define_singleton_method(:record_klass) { klass }
        string_component.define_singleton_method(:attribute_name) { 'attr' }

        text_component = Form::Element::Attribute::Text.allocate
        text_component.define_singleton_method(:record_klass) { klass }
        text_component.define_singleton_method(:attribute_name) { 'attr' }

        [string_component.default_editor, text_component.default_editor].to_n
      end
    ).to eq ['text', 'tinymce']
  end

  context 'String with attribute_format = phone' do
    before(:each) do
      page_exec do
        class Record
          def self.attribute_format(attr)
            'phone' if attr == 'attr'
          end
        end
      end
    end

    it 'renders the tel editor by default' do
      mount do
        Form(record: Record.new(attr: '')) do
          Form::Element::Attribute::String(attribute_name: 'attr')
        end
      end

      expect(page).to have_selector('button[name="btn_dropdown_countries"]')
    end

    it 'keeps the editor explicitly set on the element' do
      mount do
        Form(record: Record.new(attr: 'titi')) do
          Form::Element::Attribute::String(attribute_name: 'attr', editor: 'text')
        end
      end

      expect(page).to have_no_selector('button[name="btn_dropdown_countries"]')
      expect(find('input[name="record[attr]"]').value).to eq 'titi'
    end
  end

  context 'Text with attribute_format = raw' do
    before(:each) do
      page_exec do
        class Record
          def self.attribute_format(attr)
            'raw' if attr == 'attr'
          end
        end
      end
    end

    it 'renders a plain textarea by default' do
      mount do
        Form(record: Record.new(attr: 'titi')) do
          Form::Element::Attribute::Text(attribute_name: 'attr')
        end
      end

      expect(find('textarea[name="record[attr]"]').value).to eq 'titi'
    end
  end

end
