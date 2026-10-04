describe Dynamic::Communication::Feature, elasticsearch: true do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Communication::Feature')
  end

  context 'feature activation' do
    before(:each) do
      @contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
      @feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @contact)
    end

    context 'when enabled' do
      context 'Email' do

        context 'with Email klass missing' do

          it 'should create an Email klass' do
            expect(@schema.klasses.map(&:name)).to_not include('Email')
            @feature.update!(enabled: true)
            expect(@schema.klasses.map(&:name)).to include('Email')
          end

        end

        context 'with Email klass existing' do
          before(:each) do
            @email = @schema.klasses.create!(
              name: 'Email',
              attrs_attributes: [
                {
                  name: 'address',
                  type: 'String'
                },
                {
                  name: 'tag',
                  type: 'Enum',
                  values_attributes: [
                    {
                      name: 'Home',
                      human_name_fr: 'Domicile',
                      human_name_en: 'Home'
                    },
                    {
                      name: 'Office',
                      human_name_fr: 'Bureau',
                      human_name_en: 'Office',
                    },
                    {
                      name: 'Other',
                      human_name_fr: 'Autre',
                      human_name_en: 'Other',
                    },
                    {
                      name: 'Favorite',
                      human_name_fr: 'Préférée',
                      human_name_en: 'Favorite',
                    },
                  ]
                },
              ]
            )
            email_concern = @feature.concerns.detect {|c| c.name == 'Email'}
            email_concern.update!(klass: @email)
            email_concern.options.detect {|o| o.name == 'address_attribute'}.update!(value: @email.attrs.first)
            email_concern.options.detect {|o| o.name == 'tag_attribute'}.update!(value: @email.attrs.last)
          end

          it 'should not create another Email klass' do
            expect(@schema.klasses.count).to eq(2)
            @feature.update!(enabled: true)
            expect(@schema.klasses.count).to eq(4) #adding address and phones
          end

          it 'should add associations on Contact klass' do
            expect(@contact.associations.count).to eq(0)
            @feature.update!(enabled: true)
            expect(@contact.associations.map(&:name)).to include('emails')
            expect(@contact.associations.map(&:name)).to include('email_contact')
          end

          it 'should add an owner association on Email klass' do
            expect(@email.associations.count).to eq(0)
            @feature.update!(enabled: true)
            expect(@email.associations.map(&:name)).to include('owner')
          end

          it 'should add an email_contact association on all klasses with an emails association' do
            @toto = @schema.klasses.create!(name: 'Toto', attrs_attributes: [], associations_attributes: [name: 'emails', target_klass: @email, type: 'HasMany', human_name: 'Emails'])
            @titi = @schema.klasses.create!(name: 'Titi', attrs_attributes: [], associations_attributes: [])
            @feature.update!(enabled: true)
            expect(@toto.associations.map(&:name)).to include('email_contact')
            expect(@titi.associations.map(&:name)).to_not include('email_contact')
          end

          it 'should index address, tag and owner' do
            @feature.update!(enabled: true)
            o = @email.reload.options_for_indexed_json
            expect(o['only']).to include('address')
            expect(o['only']).to include('tag')
            expect(o['include']['owner']['only']).to eq ['id', 'created_at', 'updated_at', 'deleted_at', 'type', 'polymorphic_name']

            expect(@email.global_search_fields).to eq ['address', 'owner.polymorphic_name']
          end
        end

      end

      context 'Address' do

        context 'with Address klass missing' do

          it 'should create an Address klass' do
            expect(@schema.klasses.map(&:name)).to_not include('Address')
            @feature.update!(enabled: true)
            expect(@schema.klasses.map(&:name)).to include('Address')
          end

        end

        context 'with Address klass existing' do
          before(:each) do
            @address = @schema.klasses.create!(name: 'Address')
            @feature.concerns.detect {|c| c.name == 'Address'}.update!(klass: @address)
          end

          it 'should not create another Address klass' do
            expect(@schema.klasses.count).to eq(2)
            @feature.update!(enabled: true)
            expect(@schema.klasses.count).to eq(4) #adding emails and phones
          end

          it 'should add associations on Contact klass' do
            expect(@contact.associations.count).to eq(0)
            @feature.update!(enabled: true)
            expect(@contact.associations.map(&:name)).to include('addresses')
            expect(@contact.associations.map(&:name)).to include('address_contact')
          end

          it 'should add an owner association on Address klass' do
            expect(@address.associations.count).to eq(0)
            @feature.update!(enabled: true)
            expect(@address.associations.map(&:name)).to include('owner')
          end

          it 'should add an address_contact association on all klasses with an addresses association' do
            @toto = @schema.klasses.create!(name: 'Toto', attrs_attributes: [], associations_attributes: [name: 'addresses', target_klass: @address, type: 'HasMany', human_name: 'Addresses'])
            @titi = @schema.klasses.create!(name: 'Titi', attrs_attributes: [], associations_attributes: [])
            @feature.update!(enabled: true)
            expect(@toto.associations.map(&:name)).to include('address_contact')
            expect(@titi.associations.map(&:name)).to_not include('address_contact')
          end

        end

      end

      context 'Phone' do

        context 'with Phone klass missing' do

          it 'should create a Phone klass' do
            expect(@schema.klasses.map(&:name)).to_not include('Phone')
            @feature.update!(enabled: true)
            expect(@schema.klasses.map(&:name)).to include('Phone')
          end

        end

        context 'with Phone klass existing' do
          before(:each) do
            @phone = @schema.klasses.create!(name: 'Phone')
            @feature.concerns.detect {|c| c.name == 'Phone'}.update!(klass: @phone)
          end

          it 'should not create another Phone klass' do
            expect(@schema.klasses.count).to eq(2)
            @feature.update!(enabled: true)
            expect(@schema.klasses.count).to eq(4) #adding address and emails
          end

          it 'should add associations on Contact klass' do
            expect(@contact.associations.count).to eq(0)
            @feature.update!(enabled: true)
            expect(@contact.associations.map(&:name)).to include('phones')
            expect(@contact.associations.map(&:name)).to include('phone_contact')
          end

          it 'should add an owner association on Phone klass' do
            expect(@phone.associations.count).to eq(0)
            @feature.update!(enabled: true)
            expect(@phone.associations.map(&:name)).to include('owner')
          end

          it 'should add an phone_contact association on all klasses with an phones association' do
            @toto = @schema.klasses.create!(name: 'Toto', attrs_attributes: [], associations_attributes: [name: 'phones', target_klass: @phone, type: 'HasMany', human_name: 'Phones'])
            @titi = @schema.klasses.create!(name: 'Titi', attrs_attributes: [], associations_attributes: [])
            @feature.update!(enabled: true)
            expect(@toto.associations.map(&:name)).to include('phone_contact')
            expect(@titi.associations.map(&:name)).to_not include('phone_contact')
          end

        end

      end
    end
  end

  context 'email_contact computation' do
    before(:each) do
      User.current = User.create(last_name: 'toto', first_name: 'titi', login: 'super_toto')

      @contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
      @feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @contact)
      @feature.update!(enabled: true)
      @schema.load

      Dynamic::Elasticsearch.wait_for_complete do
        @record_contact_toto = D::My::Contact.create!(id: '0197352c-e14e-7c1a-a7b4-be4a43d56149', name: 'Toto')
        @record_email1 = D::My::Email.create!(address: 'toto@home.fr', tag: 'Home')
        @record_email2 = D::My::Email.create!(address: 'toto@office.fr', tag: 'Office')
        @record_email3 = D::My::Email.create!(address: 'toto@other.fr', tag: 'Other')
        @record_contact_toto.emails << @record_email1
        @record_contact_toto.emails << @record_email2
        @record_contact_toto.emails << @record_email3

        @record_contact_titi = D::My::Contact.create!(id: '0197352c-e297-7db1-b7ee-33b31834a8e5', name: 'Titi')
        @record_email4 = D::My::Email.create!(address: 'titi@home.fr', tag: 'Home')
        @record_email5 = D::My::Email.create!(address: 'titi@office.fr', tag: 'Office')
        @record_email6 = D::My::Email.create!(address: 'titi@other.fr', tag: 'Other')
        @record_contact_titi.emails << @record_email4
        @record_contact_titi.emails << @record_email5
        @record_contact_titi.emails << @record_email6
      end
    end

    context 'without EmailOrder' do
      it 'should not compute the email_contact' do
        expect(@record_contact_toto.email_contact.count).to eq(0)
        Dynamic::Communication::Feature.compute_email_contact(@record_contact_toto)
        expect(@record_contact_toto.email_contact.count).to eq(0)
      end
    end

    context 'with EmailOrder' do
      context 'with simple filters' do
        before(:each) do
          @email_order_toto = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
          @email_order_toto.types.create!(tag: 'Office', position: 0)
        end

        it 'should not compute the email_contact value if not in filter' do
          expect(@record_contact_titi.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_email_contact(@record_contact_titi)
          expect(@record_contact_titi.email_contact.count).to eq(0)
        end

        it 'should compute the email_contact value if in filter' do
          expect(@record_contact_toto.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_email_contact(@record_contact_toto)
          expect(@record_contact_toto.email_contact.count).to eq(1)
          expect(@record_contact_toto.email_contact.first.address).to eq('toto@office.fr')
        end

        it 'should compute the contacts from an EmailOrder' do
          expect(@record_contact_toto.email_contact.count).to eq(0)
          expect(@record_contact_titi.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_all_email_contact('my', @email_order_toto)
          expect(@record_contact_toto.email_contact.count).to eq(1)
          expect(@record_contact_toto.email_contact.first.address).to eq('toto@office.fr')
          expect(@record_contact_titi.email_contact.count).to eq(0)
        end

      end

      context 'with all filter' do
        before(:each) do
          @email_order_toto = D::My::R::EmailOrder::Base.create!(id: '0190a7a1-29d3-72ba-ad55-309bd6b2dc83', name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
          @email_order_toto.types.create!(tag: 'Office', position: 0)

          @email_order_all = D::My::R::EmailOrder::Base.create!(id: '0190a7a2-f5d3-7154-b8c2-d783d9590d22', name: 'EmailOrderAll', klass: 'contacts', schema: 'my', filters: {})
          @email_order_all.types.create!(tag: 'Home', position: 0)
        end

        it 'should compute the contacts from an EmailOrder' do
          expect(@record_contact_toto.email_contact.count).to eq(0)
          expect(@record_contact_titi.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_all_email_contact('my', @email_order_all)
          expect(@record_contact_toto.email_contact.count).to eq(1)
          expect(@record_contact_titi.email_contact.count).to eq(1)
        end

        it 'should use the first EmailOrder to compute email_contact' do
          expect(@record_contact_toto.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_email_contact(@record_contact_toto)
          expect(@record_contact_toto.email_contact.count).to eq(1)
          expect(@record_contact_toto.email_contact.first.address).to eq('toto@office.fr')
        end

      end

      context 'without filter' do
        before(:each) do
          @email_order_no_filter = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderAll', klass: 'contacts', schema: 'my')
          @email_order_no_filter.types.create!(tag: 'Other', position: 0)
        end

        it 'should compute the email_contact if no filter' do
          expect(@record_contact_titi.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_email_contact(@record_contact_titi)
          expect(@record_contact_titi.email_contact.count).to eq(1)
          expect(@record_contact_titi.email_contact.first.address).to eq('titi@other.fr')
        end

        it 'should compute all email_contact if no filter' do
          expect(@record_contact_titi.email_contact.count).to eq(0)
          expect(@record_contact_toto.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_all_email_contact('my', @email_order_no_filter)
          expect(@record_contact_titi.email_contact.count).to eq(1)
          expect(@record_contact_titi.email_contact.first.address).to eq('titi@other.fr')
          expect(@record_contact_toto.email_contact.count).to eq(1)
          expect(@record_contact_toto.email_contact.first.address).to eq('toto@other.fr')
        end

      end

      context 'with a type being nil and another being present, both with the same position' do
        before(:each) do
          @email_order_no_filter = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderAll', klass: 'contacts', schema: 'my')
          @email_order_no_filter.types.create!(tag: nil, position: 0)
          @email_order_no_filter.types.create!(tag: 'Other', position: 0)
          @record_email7 = D::My::Email.create!(address: 'titi@nil.fr', tag: nil)
          @record_contact_titi.emails << @record_email7
        end

        it 'should compute' do
          expect(@record_contact_titi.email_contact.count).to eq(0)
          Dynamic::Communication::Feature.compute_all_email_contact('my', @email_order_no_filter)
          expect(@record_contact_titi.email_contact.count).to eq(1)
          expect(@record_contact_titi.email_contact.first.address).to eq('titi@other.fr')
        end
      end

    end

    context 'after create' do
      before(:each) do
        email_order_toto = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
        email_order_toto.types.create!(tag: 'Office', position: 0)
      end

      it 'should compute email_contact' do
        Dynamic::Elasticsearch.wait_for_complete do
          D::My::Contact.create!(name: 'New toto', emails: [@record_email1, @record_email2, @record_email3])
        end

        expect(D::My::Contact.where(name: 'New toto').first.email_contact.count).to eq(1)
      end
    end

    context 'after update' do
      it 'should compute email_contact when attribute updated' do
        email_order_toto = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
        email_order_toto.types.create!(tag: 'Office', position: 0)
        @record_contact_toto.update!(name: 'New name toto')
        expect(D::My::Contact.where(name: 'New name toto').first.email_contact.count).to eq(1)
      end

      it 'should compute email_contact when inverse of owner association updated' do
        email_order_toto = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
        email_order_toto.types.create!(tag: 'Office', position: 0)
        @record_email1.update!(tag: 'Office')
        expect(D::My::Contact.where(name: 'Toto').first.email_contact.count).to eq(2)
      end

      xit 'should compute email_contact when any association updated' do
      end

      it 'should compute email_contact when email deleted' do
        email_order_toto = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
        email_order_toto.types.create!(tag: 'Office', position: 0)

        Dynamic::Communication::Feature.compute_email_contact(@record_contact_toto)
        expect(D::My::Contact.where(name: 'Toto').first.email_contact.count).to eq(1)
        @record_email2.destroy!
        expect(D::My::Contact.where(name: 'Toto').first.email_contact.count).to eq(0)
      end

      it 'should compute email_contact when email removed' do
        email_order_toto = D::My::R::EmailOrder::Base.create!(name: 'EmailOrderToto', klass: 'contacts', schema: 'my', filters: {'name'=>{'contains'=>'Toto'}})
        email_order_toto.types.create!(tag: 'Office', position: 0)

        Dynamic::Communication::Feature.compute_email_contact(@record_contact_toto)
        expect(D::My::Contact.where(name: 'Toto').first.email_contact.count).to eq(1)
        @record_contact_toto.update!(emails: [@record_email1, @record_email3])
        expect(D::My::Contact.where(name: 'Toto').first.email_contact.count).to eq(0)
      end
    end

  end

end
