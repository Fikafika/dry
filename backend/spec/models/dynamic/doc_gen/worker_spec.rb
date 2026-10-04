describe Dynamic::DocGen::Worker, elasticsearch: false, sidekiq: false do
  include ::UneekDocGen::RSpec::DocxTemplate

  before(:each) do
    @schema = Dynamic::Schema.create!({
      name: 'my',
      klasses_attributes: [{ name: 'Account', attachments_attributes: [{ name: 'attachments', type: 'HasMany' }] }],
    })
    Dynamic::Schema.load(@schema.name)

    @template = D::My::R::DocGen::DocxTemplate.create!(name: 'DOCX template', class_name: 'D::My::Account', multiple: false, docx: build_blob(docx_template_path))
    @account = D::My::Account.create!
  end

  describe 'perform' do
    context 'with attachment' do
      context 'with one record' do
        before(:each) do
          @notification = D::My::R::Notification.create!({
            state: :pending,
            #user_id: nil,
            klass_name: 'DocGen::Generation',
            data: {
              template_id: @template.id,
              record_type: @account.class.name,
              record_id: @account.id,
              attachment: 'attachments',
            },
            title_fr: I18n.t('notification.titles.doc_gen', template: @template.name, klass: @schema.klasses.first.human_name),
          })
          @generation_attributes = {
            id: ActiveRecord::Base.connection.select_value('SELECT uuid_generate_v7()'),
            records: @account,
            template: @template,
            attachment: 'attachments',
            output_name: 'file',
            prevent_progress_success: true,
            options: {
              output_mode: :save,
            },
          }
          @args = [*::Dynamic::DocGen::Worker.serialize_args(@account.class, @generation_attributes), { 'progress' => @notification.progress }]
        end

        context '' do
          before(:each) do
            @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
          end

          it 'should be successful' do
            expect(@result.output).to be_a(ActiveStorage::Blob)
            expect(@notification.reload.final_state).to eq('succeeded')
          end

          it 'should attach blob to record' do
            expect(@account.reload.attachments.map(&:blob_id)).to include(@result.output.id)
          end

          it 'should add blob data to notification' do
            expect(@notification.reload.data['active_storage_attachment']).to eq({
              'blob_id' => @result.output.id,
              'signed_id' => @result.output.signed_id,
              'filename' => 'file.docx',
            })
          end
        end

        context 'when record is destroyed' do
          before(:each) do
            @account.destroy
            @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
          end

          it 'should not be successful' do
            expect(@result).to be_nil
            expect(@notification.reload).to have_attributes({
              final_state: 'failed',
              data_errors: [{ 'type' => 'ActiveRecord::RecordNotFound', 'message' => match(/D::My::Account(?:.*)#{@account.id}/), 'backtrace' => be_present }],
            })
          end
        end

        context 'when template is destroyed' do
          before(:each) do
            @template.destroy
            @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
          end

          it 'should not be successful' do
            expect(@result).to be_nil
            expect(@notification.reload).to have_attributes({
              final_state: 'failed',
              data_errors: [{ 'type' => 'ActiveRecord::RecordNotFound', 'message' => match(/D::My::R::DocGen::Template(?:.*)#{@template.id}/), 'backtrace' => be_present }],
            })
          end
        end

        context 'with webhook url' do
          before(:each) do
            stub_request(:post, 'http://test.ex/api/generations').to_return do |request|
              @webhook_data = JSON.parse(request.body)
              { status: Rack::Utils.status_code(:accepted) }
            end
            @generation_attributes[:options][:webhook_url] = 'http://test.ex/api/generations'
            @args = [*::Dynamic::DocGen::Worker.serialize_args(@account.class, @generation_attributes), { 'progress' => @notification.progress }]
          end

          context '' do
            before(:each) do
              @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
            end

            it 'should be successful' do
              expect(@result.output).to be_a(ActiveStorage::Blob)
              expect(@notification.reload.final_state).to eq('succeeded')
            end

            it 'should trigger webhook' do
              expect(a_request(:post, 'http://test.ex/api/generations')).to have_been_made.once
              expect(@webhook_data).to eq({
                'generation' => {
                  'id' => @generation_attributes[:id],
                  'state' => 'success',
                  'active_storage_attachment' => {
                    'blob_id' => @result.output.id,
                    'signed_id' => @result.output.signed_id,
                    'filename' => 'file.docx',
                  },
                },
              })
            end
          end

          context 'without notification' do
            before(:each) do
              @args.pop
              @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
            end

            it 'should be successful' do
              expect(@result.output).to be_a(ActiveStorage::Blob)
              expect(@notification.reload.final_state).to be_nil
            end

            it 'should trigger webhook' do
              expect(a_request(:post, 'http://test.ex/api/generations')).to have_been_made.once
              expect(@webhook_data).to eq({
                'generation' => {
                  'id' => @generation_attributes[:id],
                  'state' => 'success',
                  'active_storage_attachment' => {
                    'blob_id' => @result.output.id,
                    'signed_id' => @result.output.signed_id,
                    'filename' => 'file.docx',
                  },
                },
              })
            end
          end

          context 'when record is destroyed' do
            before(:each) do
              @account.destroy
              @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
            end

            it 'should trigger webhook' do
              expect(a_request(:post, 'http://test.ex/api/generations')).to have_been_made.once
              expect(@webhook_data).to match({
                'generation' => {
                  'id' => @generation_attributes[:id],
                  'state' => 'fail',
                  'errors' => [{ 'type' => 'ActiveRecord::RecordNotFound', 'message' => match(/D::My::Account(?:.*)#{@account.id}/), 'backtrace' => be_present }],
                },
              })
            end
          end
        end

        context 'without notification' do
          before(:each) do
            @args.pop
            @result = ::Dynamic::DocGen::Worker.new.perform(*@args)
          end

          it 'should be successful' do
            expect(@result.output).to be_a(ActiveStorage::Blob)
          end
        end
      end

      context 'with many records' do
        before(:each) do
          @notification = D::My::R::Notification.create!({
            state: :pending,
            #user_id: nil,
            klass_name: 'DocGen::Generation',
            data: {
              template_id: @template.id,
              record_type: @account.class.name,
              record_id: nil,
              attachment: 'attachments',
            },
            title_fr: I18n.t('notification.titles.doc_gen', template: @template.name, klass: @schema.klasses.first.human_name),
          })
          generation_attributes = {
            records: [@account],
            template: @template,
            attachment: 'attachments',
            output_name: '',
            prevent_progress_success: true,
            options: {
              output_mode: :save,
              notification: @notification,
            },
          }
          args = [*::Dynamic::DocGen::Worker.serialize_args(@account.class, generation_attributes), { 'progress' => @notification.progress }]
          @result = ::Dynamic::DocGen::Worker.new.perform(*args)
        end

        it 'should be successful' do
          expect(@result.output).to be_a(ActiveStorage::Blob)
          expect(@result.output.filename.extension).to eq('zip')
          expect(@notification.reload.final_state).to eq('succeeded')
        end

        it 'should attach blob to record' do
          expect(@account.reload.attachments).to be_present
        end

        it 'should attach blob to notification' do
          expect(@notification.reload.data['active_storage_attachment']).to match({
            'blob_id' => @result.output.id,
            'signed_id' => @result.output.signed_id,
            'filename' => be_present,
          })
        end
      end
    end

    context 'without attachment' do
      before(:each) do
        @notification = D::My::R::Notification.create!({
          state: :pending,
          #user_id: nil,
          klass_name: 'DocGen::Generation',
          data: {
            template_id: @template.id,
            record_type: @account.class.name,
            record_id: @account.id,
            attachment: nil,
          },
          title_fr: I18n.t('notification.titles.doc_gen', template: @template.name, klass: @schema.klasses.first.human_name),
        })
        generation_attributes = {
          records: @account,
          template: @template,
          attachment: '',
          output_name: '',
          prevent_progress_success: true,
          options: {
            output_mode: :save,
            notification: @notification,
          },
        }
        args = [*::Dynamic::DocGen::Worker.serialize_args(@account.class, generation_attributes), { 'progress' => @notification.progress }]
        @result = ::Dynamic::DocGen::Worker.new.perform(*args)
      end

      it 'should be successful' do
        expect(@result.output).to be_a(ActiveStorage::Blob)
        expect(@notification.reload.final_state).to eq('succeeded')
      end

      it 'should not attach blob to record' do
        expect(@account.reload.attachments).to be_empty
      end

      it 'should attach blob to notification' do
        expect(@notification.reload.data['active_storage_attachment']).to match({
          'blob_id' => @result.output.id,
          'signed_id' => @result.output.signed_id,
          'filename' => be_present,
        })
      end
    end
  end
end
