describe Role, elasticsearch: false, sidekiq: false do
  before(:each) do
    @community = Community.create!(name: 'My', permalink: 'my')
  end

  describe 'community admin rights' do
    before(:each) do
      @role = Role.create!(community: @community, name: 'Admin', admin: true, default: false)
      @user = User.create!(first_name: 'user', email: 'toto@bouate.mail', login: 'toto@bouate.mail')
      @user.roles << @role
    end

    context 'Dynamic::Form' do
      before(:each) do
        @klass_name = 'Dynamic::Form'
        @form = Dynamic::Form.create!(schema: Dynamic::Schema.last)
      end

      it 'should have all permissions' do
        expect(UneekPermission::Rule.find_by(receiver: @role, klass_name: @klass_name)&.permission).to eq('CRUD')
        expect(@form.can_be_read_by?(@user)).to be true
      end

      it 'should not have permissions on another community' do
        @community_2 = Community.create!(name: 'MyOther', permalink: 'my_other')
        @form_2 = Dynamic::Form.create!(schema: Dynamic::Schema.find_by(name: 'MyOther'))

        expect(@form_2.can_be_read_by?(@user)).to be false
      end

    end

  end

  describe 'menu permissions' do

    context 'on create' do
      before(:each) do
        @role_id = UUID7.generate
      end

      it 'should create permission on user_field for Menu and Menu::Item reserved klass' do
        const_reserved_name = "#{@community.schema.const.name}::#{@community.schema.class::RESERVED_CONSTANT}"
        expect{
          Role.create!(id: @role_id, community: @community, name: 'Test', admin: false)
        }.to change {
          UneekPermission::Rule.includes(:domain).where(klass_name: "#{const_reserved_name}::Menu", receiver_id: @role_id, domain: {user_field: 'id'}).count
        }.from(0).to(1).and change {
          UneekPermission::Rule.includes(:domain).where(klass_name: "#{const_reserved_name}::Menu::Item", receiver_id: @role_id, domain: {user_field: 'id'}).count
        }.from(0).to(1)
      end

      it 'should not create permission on user_field for admin' do
        expect{
          Role.create!(id: @role_id, community: @community, name: 'Admin', admin: true)
        }.to_not change{
          UneekPermission::Rule.includes(:domain).where(domain: {user_field: 'id'}, receiver_id: @role_id).count
        }
      end

    end
  end

end