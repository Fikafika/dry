describe Dynamic::Form do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'My')
  end

  describe '.as_deep_json' do
    before(:each) do
      @schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'attr', type: 'String'}])
      @schema.load
      @form = @schema.forms.create!(human_name: 'test')
      @form.elements.create!(root_klass_name: 'D::My::Klass', attribute_name: 'attr', type: 'Attribute::String')
    end

    it 'should not raise exception when preload polymorphic has_many associations' do
      includes = {
        elements: {
          include: {
            default_value_records: 1,
          },
        },
      }
      expect {
        @form.as_deep_json(include: includes, secure: false)
      }.to_not raise_exception
    end
  end

end
