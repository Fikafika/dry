describe Dynamic::Menu::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @community = Community.create!(name: 'my', permalink: 'my')
    @schema = Dynamic::Schema.where(name: @community.name.classify).first
  end
  after(:each) do
    @schema.unload
  end

  it 'should be enabled by default' do
    expect(@schema.features.map(&:name)).to include('Dynamic::Menu::Feature')
  end

  it 'should create menu constant' do
    expect{
      @schema.load
    }.to change{
      'D::My::R::Menu'.safe_constantize.present?
    }.from(false).to(true)
  end

  it 'should create menu item constant' do
    expect{
      @schema.load
    }.to change {
      'D::My::R::Menu::Item'.safe_constantize.present?
    }.from(false).to(true)
  end

  context 'add user to community' do
    before(:each) do
      @user = User.create!(last_name: 'toto', email: 'toto@titi.fr', login: 'toto@titi.fr')
      @schema.klasses.create!(human_name_fr: 'Contact', human_name_en: 'Contact')
      Dynamic::Schema.load(@schema.name)
    end

    it 'should create a menu for this user and this community' do
      expect{
        Membership.create!(user: @user, community: @community)
      }.to change{
        D::My::R::Menu.where(user_id: @user.id).count
      }.by(1)
    end

    it 'should not create another menu if user is added twice in community' do
      m = Membership.create!(user: @user, community: @community)
      m.destroy
      Membership.create!(user: @user, community: @community)
      expect(
        D::My::R::Menu.where(user_id: @user.id).count
      ).to eq(1)
    end

    it 'should create a menu items for klasses for this user and this community' do
      expect{
        Membership.create!(user: @user, community: @community)
      }.to change{
        D::My::R::Menu::Item.count
      }.by(1)
    end
  end

  context 'klass' do
    before(:each) do
      Dynamic::Schema.load(@schema.name)
      @menu = D::My::R::Menu.create!(name: 'crm')
      @updated_at = @menu.updated_at
    end

    context 'create' do

      it 'should add a menu item' do
        expect{
          @klass = @schema.klasses.create!(
            human_name_fr: 'chose',
            plural_human_name_fr: 'choses',
            human_name_en: 'thing',
            plural_human_name_en: 'things',
            icon: 'user'
          )
        }.to change{
          @menu.items.count
        }.by(1)
        @item = @menu.items.last
        expect(
          @item.label_fr
        ).to eq 'choses' # upcase ?
        expect(
          @item.link
        ).to eq '/crm/my/table/things/last_search'
        expect(
          @item.icon
        ).to eq 'user'
        expect(
          @menu.reload.updated_at
        ).not_to eq(@updated_at)
      end

    end

    context 'update' do

      context 'plural_human_name' do
        before(:each) do
          @klass = @schema.klasses.create(name: 'thing', human_name_fr: 'chose', plural_human_name_fr: 'choses')
          @item = @menu.items.last
        end

        it 'should change label if was same label' do
          expect{
            @klass.update(plural_human_name_fr: 'Machins', plural_human_name_en: 'Stuffs')
          }.to change{
            @item.reload.label_fr
          }.to 'Machins'
          expect(
            @menu.reload.updated_at
          ).not_to eq(@updated_at)
        end
      end

      context 'route_key' do
        before(:each) do
          @klass = @schema.klasses.create(name: 'thing', plural_human_name_en: 'Things')
          expect(@klass.route_key).to eq 'things'
          @item = @menu.items.last
          @item.update(link: @item.link.gsub('/last_search', '/search?q=cool%20thing'))
        end

        it 'should change link' do
          expect{
            @klass.update(plural_human_name_en: 'Stuffs')
          }.to change{
            @item.reload.link
          }.to '/crm/my/table/stuffs/search?q=cool%20thing'
          expect(
            @menu.reload.updated_at
          ).not_to eq(@updated_at)
        end
      end

      context 'icon' do
        before(:each) do
          @klass = @schema.klasses.create(name: 'thing', icon: 'user')
          @item = @menu.items.last
        end

        it 'should change icon' do # TODO if was same icon
          expect{
            @klass.update(icon: 'pen')
          }.to change{
            @item.reload.icon
          }.to 'pen'
          expect(
            @menu.reload.updated_at
          ).not_to eq(@updated_at)
        end
      end

    end

    context 'destroy' do
      before(:each) do
        @klass = @schema.klasses.create!(name: 'thing', human_name_fr: 'chose')
        @klass.reload
      end

      it 'should remove elements related to this klass' do
        expect{
          @klass.destroy
        }.to change{
          @menu.items.count
        }.by(-1)
        expect(
          @menu.reload.updated_at.to_s
        ).not_to eq(@updated_at.to_s)
      end
    end

  end

  context 'schema' do
    context 'update' do
      context 'name' do
        before(:each) do
          Dynamic::Schema.load(@schema.name)
          @menu = D::My::R::Menu.create!(name: 'crm')
          @updated_at = @menu.updated_at
          @klass = @schema.klasses.create(name: 'thing', plural_human_name_en: 'Things')
          @item = @menu.items.last
        end

        it 'should change link' do
          expect{
            @schema.update(name: 'uneek')
          }.to change{
            @item.reload.link
          }.to '/crm/uneek/table/things/last_search'
          expect(
            @menu.reload.updated_at
          ).not_to eq(@updated_at)
        end
      end
    end

  end

  context 'permissions' do
    before(:each) do
      @schema.klasses.create!(human_name_fr: 'Contact', human_name_en: 'Contact')
      @schema.load
      @toto = ::User.create!(email: 'toto@kosmopolead.com', login: 'toto@kosmopolead.com')
      @toto.memberships.create!(community: @community)
      @titi = ::User.create!(email: 'titi@kosmopolead.com', login: 'titi@kosmopolead.com')
      @titi.memberships.create!(community: @community)

      @crm_user_role = Role.create!(community: @community, name: 'crm user')
      @titi.roles << @crm_user_role

      @toto_menu = D::My::R::Menu.find_by(user_id: @toto.id)
    end

    it "should not let user read another user's menu" do
      expect(@toto_menu.can_be_read_by?(@titi)).to be false
    end

    it 'should not let user create a menu for another user' do
      expect(@toto_menu.can_be_created_by?(@titi)).to be false
    end

    it "should not let user update another user's menu" do
      expect(@toto_menu.can_be_updated_by?(@titi, user_id: @titi.id)).to be false
    end

    it "should not let user destroy another user's menu" do
      expect(@toto_menu.can_be_deleted_by?(@titi)).to be false
    end

    it "should not let user read another user's menu item" do
      expect(@toto_menu.items.first.can_be_read_by?(@titi)).to be false
    end

    it 'should not let user create a menu item for another user' do
      expect(@toto_menu.items.new(link: 'ah_ah_i_broke_your_link').can_be_created_by?(@titi)).to be false
    end

    it "should not let user update another user's menu item" do
      expect(@toto_menu.items.first.can_be_updated_by?(@titi, link: 'ah_ah_i_broke_your_link')).to be false
    end

    it "should not let user destroy another user's menu item" do
      expect(@toto_menu.items.first.can_be_deleted_by?(@titi)).to be false
    end

    context 'admin user' do
      before(:each) do
        @admin_role = Role.create!(community: @community, name: 'admin', admin: true)
        @titi.roles << @admin_role
      end

      it "should have all permissions for other users' menu" do
        expect(@toto_menu.can_be_read_by?(@titi)).to be true
        expect(@toto_menu.can_be_created_by?(@titi)).to be true
        expect(@toto_menu.can_be_updated_by?(@titi, user_id: @titi.id)).to be true
        expect(@toto_menu.can_be_deleted_by?(@titi)).to be true
      end

      it "should have all permissions for other users' menu item" do
        expect(@toto_menu.items.first.can_be_read_by?(@titi)).to be true
        expect(@toto_menu.items.new(link: 'ah_ah_i_broke_your_link').can_be_created_by?(@titi)).to be true
        expect(@toto_menu.items.first.can_be_updated_by?(@titi, link: 'ah_ah_i_broke_your_link')).to be true
        expect(@toto_menu.items.first.can_be_deleted_by?(@titi)).to be true
      end
    end
  end

end
