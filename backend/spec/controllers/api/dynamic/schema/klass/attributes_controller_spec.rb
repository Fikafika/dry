describe Api::Dynamic::Schema::Klass::AttributesController, type: :controller, elasticsearch: false, sidekiq: false do
  include ::Devise::Test::ControllerHelpers

  before(:each) do
    @community = Community.create!(name: 'My', permalink: 'my')
    @schema = @community.schema
    @Account = @schema.klasses.create!(
      name: 'Account',
    )

    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = ::User.create!(email: 'contact@kosmopolead.com', login: 'contact@kosmopolead.com')
    @user.memberships.create!(community: @community, admin: true)
    sign_in(@user)
  end

  after(:each) do
    User.current = nil
  end

  describe 'create' do
    context 'with correct params' do
      before(:each) do
        post :create, params: {
          'schema_id' => @schema.name,
          'klass_id' => @Account.id,
          'attribute' => {
            'schema_id' => @schema.name,
            'klass_id' => @Account.id,
            'name' => 'name',
            'type' => 'String',
          }
        }
      end

      it 'should have :created status' do
        expect(response).to have_http_status(:created)
      end
    end

    context 'provided column' do
      before(:each) do
        post :create, params: {
          'schema_id' => @schema.name,
          'klass_id' => @Account.id,
          'attribute' => {
            'schema_id' => @schema.name,
            'klass_id' => @Account.id,
            'column' => 10,
            'name' => 'name',
            'type' => 'String',
          }
        }
      end

      it 'should be ignored' do
        expect(response).to have_http_status(:created)
        expect(@Account.attrs.where(name: 'name').first.column).to eq 0
      end
    end
  end

  describe 'update' do
    before(:each) do
      @attr = @Account.attrs.create!(name: 'name', type: 'String')
    end

    context 'with correct params' do
      before(:each) do
        patch :update, params: {
          'schema_id' => @schema.name,
          'klass_id' => @Account.id,
          'id' => @attr.id,
          'attribute' => {
            'id' => @attr.id,
            'schema_id' => @schema.name,
            'klass_id' => @Account.id,
            'name' => 'name2',
            'type' => 'String',
          }
        }
      end

      it 'should have :ok status' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'provided id, schema_id, klass_id, baseklass_id, column, index, type, created_at, updated_at, deleted_at' do
      before(:each) do
        @t = DateTime.now
        patch :update, params: {
          'schema_id' => @schema.name,
          'klass_id' => @Account.id,
          'id' => @attr.id,
          'attribute' => {
            'id' => '019f1982-5258-7f72-b159-00429468b9c4',
            'schema_id' => '019f197c-5718-763a-b326-2cb5a35d990e',
            'klass_id' => '019f197c-66b8-7be7-9d83-c921b0ad4eba',
            'baseklass_id' => '019f197c-66b8-7be7-9d83-c921b0ad4eba',
            'column' => 10,
            'index' => true,
            'name' => 'name2',
            'type' => 'Float',
            'created_at' => @t,
            'updated_at' => @t,
            'deleted_at' => @t,
          }
        }
      end

      it 'should be ignored' do
        expect(response).to have_http_status(:ok)
        @attr = @attr.class.find(@attr.id)
        expect(@attr.name).to eq 'name2' # changed

        expect(@attr.id).to_not eq '019f1982-5258-7f72-b159-00429468b9c4'
        expect(@attr.schema_id).to eq @schema.id
        expect(@attr.klass_id).to eq @Account.id
        expect(@attr.baseklass_id).to eq @Account.id
        expect(@attr.column).to eq 0
        expect(@attr.index).to eq false
        expect(@attr.type).to eq 'String'
        expect(@attr.created_at).to_not eq @t
        expect(@attr.updated_at).to_not eq @t
        expect(@attr.deleted_at).to eq nil
      end
    end
  end
end
