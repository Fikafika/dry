describe UneekPermission::RulesController, type: :request, elasticsearch: false, sidekiq: false do
  include Devise::Test::IntegrationHelpers
  include UneekPermission::Engine.routes.url_helpers

  before(:each) do
    @user = User.create(login: "Login", email: "email@kosmopolead.com")
    @community = Community.create!(name: 'My', permalink: 'my')
    @schema = @community.schema
    @klass = @schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'name', type: 'String'}])
    @rule = UneekPermission::Rule.create!(schema: @schema, receiver: @user, klass_name: @klass.const_absolute_name, permission: '_R__')
  end

  describe 'index' do
    before(:each) do
      @params = {where: {klass_name: @klass.const_absolute_name}}
    end

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        get rules_path, params: @params
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return unauthorized' do
        get rules_path, params: @params
        expect(response).to have_http_status(401)
      end

    end

    context 'user is authenticated as community admin' do
      before(:each) do
        @user.memberships.create!(community: @community, admin: true)
        sign_in(@user)
      end

      it 'should return permissions' do
        get rules_path, params: @params
        expect(response).to have_http_status(200)
      end
    end

  end

  describe 'show' do

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        get "#{rules_path}/#{@rule.id}"
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return unauthorized' do
        get "#{rules_path}/#{@rule.id}"
        expect(response).to have_http_status(401)
      end

    end

    context 'user is authenticated as community admin' do
      before(:each) do
        @user.memberships.create!(community: @community, admin: true)
        sign_in(@user)
      end

      it 'should return permissions' do
        get "#{rules_path}/#{@rule.id}"
        expect(response).to have_http_status(200)
      end
    end

  end

  describe 'create' do
    before(:each) do
      @params = {
        rule: {
          klass_name: @klass.const_absolute_name,
          attr: 'name',
          receiver_id: @user.id,
          receiver_type: @user.class.name,
          permission: 'C___',
          format: :json
        }
      }
    end

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        post rules_path, params: @params
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return unauthorized' do
        post rules_path, params: @params
        expect(response).to have_http_status(401)
      end

    end

    context 'user is authenticated as community admin' do
      before(:each) do
        @user.memberships.create!(community: @community, admin: true)
        sign_in(@user)
      end

      it 'should return unauthorized (receiver is admin)' do
        post rules_path, params: @params
        expect(response).to have_http_status(401)
      end
    end

  end

  describe 'update' do
    before(:each) do
      @params = { rule: { permission: 'CRU_' }}
    end

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        patch "#{rules_path}/#{@rule.id}", params: @params
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return unauthorized' do
        patch "#{rules_path}/#{@rule.id}", params: @params
        expect(response).to have_http_status(401)
      end

    end

    context 'user is authenticated as community admin' do
      before(:each) do
        @user.memberships.create!(community: @community, admin: true)
        sign_in(@user)
      end

      it 'should return permissions (receiver is admin)' do
        patch "#{rules_path}/#{@rule.id}", params: @params
        expect(response).to have_http_status(401)
      end
    end

  end

  describe 'destroy' do

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        delete "#{rules_path}/#{@rule.id}"
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return unauthorized' do
        delete "#{rules_path}/#{@rule.id}"
        expect(response).to have_http_status(401)
      end

    end

    context 'user is authenticated as community admin' do
      before(:each) do
        @user.memberships.create!(community: @community, admin: true)
        sign_in(@user)
      end

      it 'should return permissions' do
        delete "#{rules_path}/#{@rule.id}"
        expect(response).to have_http_status(204)
      end
    end

  end

end