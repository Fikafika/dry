describe UneekPermission::UsersForInstancesController, type: :request, elasticsearch: false, sidekiq: false do
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
      @schema.load
      @record = D::My::Klass.create!(name: 'toto')
      @params = { where: {klass_name: @klass.const_absolute_name, instance_id: @record.id, action: 'R'} }
    end

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        get users_for_instances_path, params: @params
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return unauthorized' do
        get users_for_instances_path, params: @params
        expect(response).to have_http_status(401)
      end

    end

    context 'user is authenticated as community admin' do
      before(:each) do
        @user.memberships.create!(community: @community, admin: true)
        sign_in(@user)
      end

      it 'should return unauthorized' do
        get users_for_instances_path, params: @params
        expect(response).to have_http_status(401)
      end
    end

    context 'user is authenticated as super admin' do
      before(:each) do
        @user.update!(super_admin: true)
        sign_in(@user)
      end

      it 'should return permissions' do
        get users_for_instances_path, params: @params
        expect(response).to have_http_status(200)
      end
    end

  end

end