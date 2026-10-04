describe SchemaDefaultValuesInForm, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.find_by(name: 'my')
    @schema.destroy if @schema.present?
    @schema = Dynamic::Schema.create!(name: 'my')
    @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
    @Account = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])
    @schema.load
    @contact = D::My::Contact.create!(name: 'Default')
  end

  describe '.any?' do
    it 'is false when the klass has no default value' do
      expect(SchemaDefaultValuesInForm.any?(D::My::Account.new)).to eq false
    end

    it 'is true when the klass has a default value on an attribute' do
      @Account.attrs.where(name: 'name').first.update!(default_value: 'hello')
      @schema.load

      expect(SchemaDefaultValuesInForm.any?(D::My::Account.new)).to eq true
    end

    it 'is true when the klass has a default value on a has_many association only' do
      assoc = @Account.associations.create!(name: 'contacts', target_klass: @Contact, type: 'HasMany')
      assoc.update!(default_value_records: [@contact])
      @schema.load

      expect(SchemaDefaultValuesInForm.any?(D::My::Account.new)).to eq true
    end
  end

  describe '.default_value?' do
    context 'attribute' do
      before(:each) do
        @Account.attrs.where(name: 'name').first.update!(default_value: 'hello')
        @schema.load
      end

      it 'is true when the value is the schema default' do
        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new, 'name')).to eq true
      end

      it 'is false when the value has been changed' do
        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new(name: 'world'), 'name')).to eq false
      end
    end

    context 'belongs_to association' do
      before(:each) do
        assoc = @Account.associations.create!(name: 'contact', target_klass: @Contact, type: 'BelongsTo')
        assoc.update!(default_value_record: @contact)
        @schema.load
      end

      it 'is true when the record is the schema default' do
        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new, 'contact')).to eq true
        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new, 'contact_id')).to eq true
      end

      it 'is false when another record has been set' do
        other = D::My::Contact.create!(name: 'Other')

        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new(contact: other), 'contact')).to eq false
      end
    end

    context 'has_many association' do
      before(:each) do
        assoc = @Account.associations.create!(name: 'contacts', target_klass: @Contact, type: 'HasMany')
        assoc.update!(default_value_records: [@contact])
        @schema.load
      end

      it 'is true when the records are the schema default' do
        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new, 'contacts')).to eq true
        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new, 'contact_ids')).to eq true
      end

      it 'is false when other records have been set' do
        other = D::My::Contact.create!(name: 'Other')

        expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new(contacts: [other]), 'contacts')).to eq false
      end
    end

    it 'is false for an attribute without schema default' do
      expect(SchemaDefaultValuesInForm.default_value?(D::My::Account.new, 'name')).to eq false
    end
  end
end
