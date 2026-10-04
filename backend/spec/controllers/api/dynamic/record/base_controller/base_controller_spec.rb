describe Api::Dynamic::Record::BaseController, type: :controller do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @user = User.create(login: "Login", email: "email@kosmopolead.com")
    @community = Community.create!(name: 'My', permalink: 'my')
    @schema = @community.schema
    @klass = @schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'name', type: 'String'}])
  end

  context 'bulk actions' do
    before(:each) do
      @schema.load
      @records = D::My::Klass.create!([
        {name: 'toto'},
        {name: 'titi'},
      ])
    end

    actions = {
      'update_all' => :patch,
      'destroy_all' => :delete
    }

    actions.each do |action, verb|

      describe action do

        context 'user is unauthenticated' do

          it 'should redirect to login' do
            send(verb, action.to_sym, params: {schema_name: @schema.name, klass_name: @klass.name})
            expect(response).to have_http_status(302)
          end

          context 'public klass' do
            before(:each) do
              UneekPermission::Rule.create!(
                schema: @schema,
                receiver: UneekPermission::PredefinedReceiver::Public.instance,
                permission: '_R__',
                klass_name: 'D::My::Klass',
              )
            end

            it 'should redirect to login' do
              send(verb, action.to_sym, params: {schema_name: @schema.name, klass_name: @klass.name})
              expect(response).to have_http_status(302)
            end

          end

          context 'private klass' do
            before(:each) do
              UneekPermission::Rule.create!(
                schema: @schema,
                receiver: @user,
                permission: '_R__',
                klass_name: 'D::My::Klass',
              )
            end

            it 'should not authorize action' do
              send(verb, action.to_sym, params: {schema_name: @schema.name, klass_name: @klass.name})
              expect(response).to have_http_status(302)
            end

          end

        end

        context 'user is authenticated' do
          before(:each) do
            sign_in(@user)
          end

          context 'private klass' do
            before(:each) do
              UneekPermission::Rule.create!(
                schema: @schema,
                receiver: @user,
                permission: '_R__',
                klass_name: 'D::My::Klass',
              )
            end

            it 'should not authorize' do
              send(verb, action.to_sym, params: {schema_name: @schema.name, klass_name: @klass.name})
              expect(response).to have_http_status(401).or have_http_status(422)
            end

          end

        end

        context 'user is admin' do
          before(:each) do
            @user.update!(super_admin: true)
            sign_in(@user)
          end

          it 'should authorize action' do
            params = {schema_name: @schema.name, klass_name: @klass.name}
            params[:base] = {name: 'tata'} if action == 'update_all'
            send(verb, action.to_sym, params: params)

            case action
            when 'update_all'
              expect(response).to have_http_status(200)
            when 'destroy_all'
              expect(response).to have_http_status(200)
            end
          end
        end

      end
    end
  end

end