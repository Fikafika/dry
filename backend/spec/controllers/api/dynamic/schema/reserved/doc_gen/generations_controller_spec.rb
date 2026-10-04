describe Api::Dynamic::Schema::Reserved::DocGen::GenerationsController, type: :controller, elasticsearch: false, sidekiq: false do
  include ::Devise::Test::ControllerHelpers
  include ::UneekDocGen::RSpec::DocxTemplate

  before(:each) do
    @doc_gen_worker_args = []
    allow_any_instance_of(Sidekiq::Client).to receive(:raw_push).and_wrap_original do |m, *args, &block|
      args.first.each do |p|
        @doc_gen_worker_args << p['args'] if p['class'] == 'Dynamic::DocGen::Worker'
      end
    end

    @community = Community.create!(name: 'My', permalink: 'my')
    @schema = @community.schema
    @schema.klasses.create!(
      name: 'Account',
      attachments_attributes: [
        { name: 'attachments', type: 'HasMany' }
      ],
    )
    Dynamic::Schema.load(@schema.name)

    @template = D::My::R::DocGen::DocxTemplate.create!(name: 'DOCX template', class_name: 'D::My::Account', multiple: false, docx: build_blob(docx_template_path))
    @account = D::My::Account.create!

    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = ::User.create!(email: 'contact@kosmopolead.com', login: 'contact@kosmopolead.com')
    @user.memberships.create!(community: @community, admin: true)
    sign_in(@user)
  end

  after(:each) do
    User.current = nil
  end

  describe 'create' do
    context 'with one record' do
      context 'with notification' do
        before(:each) do
          post :create, params: {
            'schema_id' => @schema.name,
            'klass_id' => @schema.klasses.first.to_param,
            'template_id' => @template.id,
            'generation' => {
              'record_id' => @account.id,
              'template_id' => @template.id,
              'output_name' => 'file',
            }
          }
        end

        it 'should have :created status' do
          expect(response).to have_http_status(:created)
        end

        it 'should return generation attributes' do
          expect(JSON.parse(response.body)).to match({
            'id' => be_present,
            'klass_id' => 'D::My::Account',
            'template_id' => @template.id,
            'output_name' => 'file',
            'super_merge' => false,
            'merge' => false,
            'attachment' => nil,
            'options' => { 'output_mode' => 'save' },
            'prevent_progress_success' => true,
          })
        end

        it 'should enqueue Dynamic::DocGen::Worker' do
          expect(@doc_gen_worker_args.count).to eq(1)
          expect(@doc_gen_worker_args.first[0]).to eq('D::My::Account')
          expect(YAML.load(@doc_gen_worker_args.first[1])).to match({ id: be_present, super_merge: nil, merge: nil, files: nil, attachment: nil, output_name: 'file', records: @account.id, template: @template.id, prevent_progress_success: true, options: { output_mode: :save } })
        end

        it 'should create notification' do
          expect(D::My::R::Notification.find(@doc_gen_worker_args.first[2]['notification_id'])).to have_attributes({
            "title_#{I18n.locale}": I18n.t('notification.titles.doc_gen', template: @template.name, klass: @schema.klasses.first.human_name),
            state: 'pending',
            user_id: @user.id,
            klass_name: 'DocGen::Generation',
            data: {
              'template_id' => @template.id,
              'record_type' => 'D::My::Account',
              'record_id' => @account.id,
              'attachment' => nil,
            },
          })
        end
      end

      context 'without notification' do
        before(:each) do
          post :create, params: { 'schema_id' => @schema.name, 'klass_id' => @schema.klasses.first.to_param, 'template_id' => @template.id , 'generation' => { 'record_id' => @account.id, 'template_id' => @template.id, 'output_name' => 'file', 'options' => { 'notification' => '' } } }
        end

        it 'should return generation attributes' do
          expect(JSON.parse(response.body)).to match({
            'id' => be_present,
            'klass_id' => 'D::My::Account',
            'template_id' => @template.id,
            'output_name' => 'file',
            'super_merge' => false,
            'merge' => false,
            'attachment' => nil,
            'options' => { 'output_mode' => 'save', 'notification' => '' },
            'prevent_progress_success' => true,
          })
        end

        it 'should enqueue Dynamic::DocGen::Worker' do
          expect(@doc_gen_worker_args.count).to eq(1)
          expect(@doc_gen_worker_args.first[0]).to eq('D::My::Account')
          expect(YAML.load(@doc_gen_worker_args.first[1])).to match({ id: be_present, super_merge: nil, merge: nil, files: nil, attachment: nil, output_name: 'file', records: @account.id, template: @template.id, prevent_progress_success: true, options: { output_mode: :save, notification: '' } })
        end

        it 'should not create new notification' do
          expect(@doc_gen_worker_args.first[2].has_key?('notification_attributes')).to be false
          expect(D::My::R::Notification.where(klass_name: 'DocGen::Generation').count).to eq(0)
        end
      end

      context 'with webhook_url' do
        context 'with notification' do
          before(:each) do
            post :create, params: { 'schema_id' => @schema.name, 'klass_id' => @schema.klasses.first.to_param, 'template_id' => @template.id , 'generation' => { 'record_id' => @account.id, 'template_id' => @template.id, 'output_name' => 'file', 'options' => { 'webhook_url' => 'http://text.ex/api/generations' } } }
          end

          it 'should return generation attributes' do
            expect(JSON.parse(response.body)).to match({
              'id' => be_present,
              'klass_id' => 'D::My::Account',
              'template_id' => @template.id,
              'output_name' => 'file',
              'super_merge' => false,
              'merge' => false,
              'attachment' => nil,
              'options' => { 'output_mode' => 'save', 'webhook_url' => 'http://text.ex/api/generations' },
              'prevent_progress_success' => true,
            })
          end

          it 'should enqueue Dynamic::DocGen::Worker' do
            expect(@doc_gen_worker_args.count).to eq(1)
            expect(@doc_gen_worker_args.first[0]).to eq('D::My::Account')
            expect(YAML.load(@doc_gen_worker_args.first[1])).to match({ id: be_present, super_merge: nil, merge: nil, files: nil, attachment: nil, output_name: 'file', records: @account.id, template: @template.id, prevent_progress_success: true, options: { output_mode: :save, webhook_url: 'http://text.ex/api/generations' } })
          end
        end
      end
    end

    context 'with many records' do
      before(:each) do
        @account2 = D::My::Account.create!
        post :create, params: {
          'schema_id' => @schema.name,
          'klass_id' => @schema.klasses.first.to_param,
          'template_id' => @template.id,
          'generation' => {
            'record_ids' => [@account.id, @account2.id],
            'template_id' => @template.id,
            'attachment' => 'attachments'
          }
        }
      end

      it 'should have :created status' do
        expect(response).to have_http_status(:created)
      end

      it 'should return generation attributes' do
        expect(JSON.parse(response.body)).to match({
          'id' => be_present,
          'klass_id' => 'D::My::Account',
          'template_id' => @template.id,
          'super_merge' => false,
          'merge' => false,
          'attachment' => 'attachments',
          'output_name' => nil,
          'options' => { 'output_mode' => 'save' },
          'prevent_progress_success' => true,
        })
      end

      it 'should enqueue Dynamic::DocGen::Worker' do
        expect(@doc_gen_worker_args.count).to eq(1)
        expect(@doc_gen_worker_args.first[0]).to eq('D::My::Account')
        expect(YAML.load(@doc_gen_worker_args.first[1])).to match({ id: be_present, super_merge: nil, merge: nil, files: nil, attachment: 'attachments', output_name: nil, records: [@account.id, @account2.id], template: @template.id, prevent_progress_success: true, options: { output_mode: :save } })
      end

      it 'should create notification' do
        expect(D::My::R::Notification.find(@doc_gen_worker_args.first[2]['notification_id'])).to have_attributes({
          "title_#{I18n.locale}": I18n.t('notification.titles.doc_gen', template: @template.name, klass: @schema.klasses.first.human_name),
          state: 'pending',
          user_id: @user.id,
          klass_name: 'DocGen::Generation',
          data: {
            'template_id' => @template.id,
            'record_type' => 'D::My::Account',
            'record_id' => nil,
            'attachment' => 'attachments',
          },
        })
      end
    end

    context 'with invalid data' do
      before(:each) do
        @account2 = D::My::Account.create!
        post :create, params: { 'schema_id' => @schema.name, 'klass_id' => @schema.klasses.first.to_param, 'template_id' => @template.id , 'generation' => { 'record_ids' => [@account.id, @account2.id], 'template_id' => @template.id } }
      end

      it 'should have :unprocessable_content status' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'should return errors' do
        expect(JSON.parse(response.body)).to eq({ 'attachment' => [{ 'error' => 'blank' }] })
      end

      it 'should not enqueue Dynamic::DocGen::Worker' do
        expect(@doc_gen_worker_args).to be_empty
      end
    end

    context 'with invalid permissions' do
      before(:each) do
        @user.memberships.first.update!(admin: false)
        @role = @community.roles.create!(name: 'CRM user')
        @user.roles << @role
        UneekPermission::Rule.create!(
          schema: @schema,
          receiver: @role,
          permission: '_R__',
          klass_name: 'D::My::R::DocGen::Template',
        )
      end

      it 'should have :unauthorized status' do
        post :create, params: {
          'schema_id' => @schema.name,
          'klass_id' => @schema.klasses.first.to_param,
          'template_id' => @template.id ,
          'generation' => {
            'record_id' => @account.id,
            'template_id' => @template.id,
            'output_name' => 'file',
            'options' => { 'notification' => '' }
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
