describe Api::Dynamic::Schema::FormsController, type: :controller, elasticsearch: false, sidekiq: false do
  include ::Devise::Test::ControllerHelpers

  before(:each) do
    @community = Community.create!(name: 'My', permalink: 'my')
    @user = User.create(login: "Login", email: "email@kosmopolead.com", communities: [@community])
    @schema = @community.schema
    @klass = @schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'name', type: 'String'}])
    @form = Dynamic::Form.first
  end

  let(:crud_actions){['index', 'show', 'create', 'duplicate', 'update', 'delete']}
  let(:post_actions){['submit', 'submit_all', 'save_as_draft']}

  describe 'show' do

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        get :show, params: {schema_id: @schema.name, id: @form.id}
        expect(response).to have_http_status(302)
      end

      context 'public form' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: UneekPermission::PredefinedReceiver::Public.instance,
            permission: '_R__',
            klass_name: 'Dynamic::Form',
          )
        end

        it 'should return form' do
          get :show, params: {schema_id: @schema.name, id: @form.id}
          expect(response).to have_http_status(200)
        end

      end

    end

    context 'user is connected with session' do
      before(:each) do
        sign_in(@user)
        @rule = UneekPermission::Rule.create!(
          schema: @schema,
          receiver: @user,
          permission: '_R__',
          klass_name: 'Dynamic::Form',
        )
      end

      context 'including can_be_updated_by_current_user?' do

        it 'should be false without right to update' do
          get :show, params: {schema_id: @schema.name, id: @form.id, include: {'can_be_updated_by_current_user?': true}}
          expect(JSON.parse(response.body)['can_be_updated_by_current_user?']).to eq(false)
        end

        context 'with right to update' do
          before(:each) do
            @rule.update!(permission: '_RU_')
          end

          it 'should be true' do
            get :show, params: {schema_id: @schema.name, id: @form.id, include: {'can_be_updated_by_current_user?': true}}
            expect(JSON.parse(response.body)['can_be_updated_by_current_user?']).to eq(true)
          end

        end

        context 'being community admin' do
          before(:each) do
            @user.memberships.first.update!(admin: true)
          end

          it 'should be true' do
            get :show, params: {schema_id: @schema.name, id: @form.id, include: {'can_be_updated_by_current_user?': true}}
            expect(JSON.parse(response.body)['can_be_updated_by_current_user?']).to eq(true)
          end

        end

      end

    end

  end

  describe 'submit' do

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        post :submit, params: {schema_id: @schema.name, id: @form.id}
        expect(response).to have_http_status(302)
      end

      context 'public form' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: UneekPermission::PredefinedReceiver::Public.instance,
            permission: '_R__',
            klass_name: 'Dynamic::Form',
          )
        end

        it 'should return form' do
          post :submit, params: {schema_id: @schema.name, id: @form.id}
          expect(response).to have_http_status(200)
        end

        context 'submission date is expired' do
          before(:each) do
            @form.update(start_date: DateTime.current - 3.days, end_date: DateTime.current - 2.days)
          end

          it 'should be forbidden' do
            post :submit, params: {schema_id: @schema.name, id: @form.id}
            expect(response).to have_http_status(403)
          end
        end

        context 'empty CSRF token' do

          it 'should return form' do
            request.headers['X-CSRF-Token'] = nil
            post :submit, params: {schema_id: @schema.name, id: @form.id}
            expect(response).to have_http_status(200)
          end

        end

      end

      context 'rule on form' do
        before(:each) do
          @role = @community.roles.create!(name: 'élève')
          @user.roles << @role
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @role,
            permission: '_R__',
            klass_name: 'Dynamic::Form',
          )
        end

        it 'should redirect to login' do
          post :submit, params: {schema_id: @schema.name, id: @form.id}
          expect(response).to have_http_status(302)
        end

        context 'user is authenticated' do
          before(:each) do
            sign_in(@user)
          end

          it 'should be successful' do
            post :submit, params: {schema_id: @schema.name, id: @form.id}
            expect(response).to have_http_status(200)
          end

          context 'submission date is expired' do
            before(:each) do
              @form.update(start_date: DateTime.current - 3.days, end_date: DateTime.current - 2.days)
            end

            it 'should be forbidden' do
              post :submit, params: {schema_id: @schema.name, id: @form.id}
              expect(response).to have_http_status(403)
            end
          end

        end

      end

    end

    context 'user is connected with session' do
    end

    context 'user is connected with jwt' do
    end

    context 'user is connected with both session and jwt' do
    end

  end

  describe 'update' do

    context 'user is unauthenticated' do

      it 'should redirect to login' do
        put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
        expect(response).to have_http_status(302)
      end

      context 'public form' do
        before(:each) do
          UneekPermission::Rule.create!(
            schema: @schema,
            receiver: UneekPermission::PredefinedReceiver::Public.instance,
            permission: '_R__',
            klass_name: 'Dynamic::Form',
          )
        end

        it 'should redirect to login' do
          put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
          expect(response).to have_http_status(302)
        end

      end

    end

    context 'user is connected with session' do
      before(:each) do
        sign_in(@user)
      end

      context 'withtout right to update' do

        it 'should return unhautorized' do
          put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
          expect(response).to have_http_status(401)
        end

        context 'public form' do
          before(:each) do
            UneekPermission::Rule.create!(
              schema: @schema,
              receiver: UneekPermission::PredefinedReceiver::Public.instance,
              permission: '_R__',
              klass_name: 'Dynamic::Form',
            )
          end

          it 'should return unhautorized' do
            put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
            expect(response).to have_http_status(401)
          end

        end
      end

      context 'with right to update' do
        before(:each) do
          @rule = UneekPermission::Rule.create!(
            schema: @schema,
            receiver: @user,
            permission: '__U_',
            klass_name: 'Dynamic::Form',
          )
        end

        it 'should be successful' do
          put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
          expect(response).to have_http_status(200)
        end

        context 'public form' do
          before(:each) do
            @rule.update!(receiver: UneekPermission::PredefinedReceiver::Public.instance)
          end

          it 'should be successful' do
            put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
            expect(response).to have_http_status(200)
          end

        end

        context 'and being community admin' do
          before(:each) do
            @user.memberships.first.update!(admin: true)
          end

          it 'should return ok' do
            put :update, params: {schema_id: @schema.name, id: @form.id, form: {mode: :input}}
            expect(response).to have_http_status(200)
          end
        end
      end

    end
  end

end