describe UneekDocGen::Formula::Function::RedirectionUrl do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'My')
  end

  context 'Form' do
    before(:each) do
      @schema.klasses.create!(
        name: 'Contact',
        attrs_attributes: [
          {name: 'first_name', type: 'String'},
          {name: 'last_name', type: 'String'},
        ]
      )
      @schema.load
      @form = @schema.forms.create!(human_name: 'test')
      @form.elements.create!(root_klass_name: 'D::My::Contact', attribute_name: 'last_name', type: 'Attribute::String')
      @form.elements.create!(root_klass_name: 'D::My::Contact', attribute_name: 'first_name', type: 'Attribute::String')

      @contact = D::My::Contact.create!(last_name: 'A', first_name: 'a')

      @redirection = @schema.redirections.create!(
        name: 'form',
        target_type: 'Form',
      )
    end

    it 'should generate url' do
      formula = %Q[redirection_url("#{@redirection.name}")]
      expect(
        UneekDocGen::Formula.new(formula).eval(record: @contact)
      ).to eq "#{ENV['DYNAMO_PROTOCOL']}://#{ENV['DYNAMO_HOST']}/crm/my/redirections/form?for=#{@contact.id}"
    end

  end

end
