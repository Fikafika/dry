describe Dynamic::Redirection do
  around(:each) do |example|
    without_partial_double_verification do # fix allow_any_instance_of for active_record
      example.run
    end
  end
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'My')
    @Contact = @schema.klasses.create!(
      name: 'Contact',
      attrs_attributes: [
        {name: 'first_name', type: 'String'},
        {name: 'last_name', type: 'String'},
      ]
    )
  end

  describe '#evaluate' do

    context 'permissions' do

      context 'Form' do
        before(:each) do
          @schema.load

          @contact = D::My::Contact.create!(last_name: 'A', first_name: 'a')

          @form = @schema.forms.create!(human_name: 'test')
          @form.elements.create!(root_klass_name: 'D::My::Contact', attribute_name: 'last_name', type: 'Attribute::String')
          @form.elements.create!(root_klass_name: 'D::My::Contact', attribute_name: 'first_name', type: 'Attribute::String')

          @redirection = @schema.redirections.create!(
            name: 'form',
            klass: @Contact,
            condition_type: 'Permission',
            target_type: 'Form',
            target_params: {
              form_id: @form.id,
            },
          )

          @params = {for: @contact.id}.with_indifferent_access
        end

        it 'should return type == target_type if permitted' do
          allow_any_instance_of(Dynamic::Form).to receive(:can_be_read_by?).and_return(true)
          allow_any_instance_of(D::My::Contact).to receive(:can_be_read_by?).and_return(true)
          expect(
            @redirection.evaluate(@params)[:type]
          ).to eq @redirection.target_type
        end

        it 'should return type == fallback_type if not permitted' do
          allow_any_instance_of(Dynamic::Form).to receive(:can_be_read_by?).and_return(false)
          expect(
            @redirection.evaluate(@params)[:type]
          ).to eq @redirection.fallback_type
        end

        it 'should return computed params if permitted' do
          allow_any_instance_of(Dynamic::Form).to receive(:can_be_read_by?).and_return(true)
          allow_any_instance_of(D::My::Contact).to receive(:can_be_read_by?).and_return(true)
          expect(
            @redirection.evaluate(@params)[:params]
          ).to eq(
            {schema_id: @schema.name, form_id: @form.id, klass_name: 'D::My::Contact', id: @contact.id}
          )
        end

      end

      context 'Vcard' do
        before(:each) do
          @feature = @schema.features.detect{|f| f.name == 'Dynamic::Vcard::Feature'}

          @feature.concerns.create!(name: 'Vcard', klass_id: @Contact.id)

          @schema.load

          @contact = D::My::Contact.create!(last_name: 'A', first_name: 'a')

          @redirection = @schema.redirections.create!(
            name: 'vcard',
            klass: @Contact,
            condition_type: 'Permission',
            target_type: 'Vcard',
            target_params: {
              klass_id: @Contact.id,
            },
          )

          @params = {for: @contact.id}.with_indifferent_access
        end

        it 'should return type == Vcard if permitted' do
          allow_any_instance_of(D::My::Contact).to receive(:can_be_read_by?).and_return(true)
          expect(
            @redirection.evaluate(@params)[:type]
          ).to eq @redirection.target_type
        end

        it 'should return computed params if permitted' do
          allow_any_instance_of(D::My::Contact).to receive(:can_be_read_by?).and_return(true)
          expect(
            @redirection.evaluate(@params)[:params]
          ).to eq(
            {schema_name: 'my', route_key: 'contacts', id: @contact.id}
          )
        end

        it 'should return type == fallback_type if not permitted' do
          allow_any_instance_of(D::My::Contact).to receive(:can_be_read_by?).and_return(false)
          expect(
            @redirection.evaluate(@params)[:type]
          ).to eq @redirection.fallback_type
        end

      end
    end
  end

end
