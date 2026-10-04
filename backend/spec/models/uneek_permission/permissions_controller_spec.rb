describe UneekPermission::PermissionsController, type: :request, elasticsearch: false, sidekiq: false do
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
      @params = {klass_name: @klass.const_absolute_name, user_id: @user.id}
    end

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        get permissions_path, params: @params
        expect(response).to have_http_status(302)
      end

    end

    context 'user is authenticated' do
      before(:each) do
        sign_in(@user)
      end

      it 'should return authorized' do
        get permissions_path, params: @params
        expect(response).to have_http_status(200)
      end

      xit 'should access only its own permissions' do
      end

      context 'user is admin' do

        xit 'should access permissions of other users' do
        end
      end
    end

  end

end