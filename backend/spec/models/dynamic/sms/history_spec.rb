require 'securerandom'

describe Dynamic::Sms::History, elasticsearch: false, sidekiq: false, type: :request do

  include ::Devise::Test::IntegrationHelpers

  before(:each) do
    @base_url = "#{ENV['SMS_API_PROTOCOL']}://#{ENV['SMS_API_HOST']}#{":#{ENV['SMS_API_PORT']}" if ENV['SMS_API_PORT']}"
    @id = '07081a6e-f666-43a9-ba5c-ab4a20a6bf57'
    @client_name = 'My'
    @user = User.create(login: "Login", email: "email@kosmopolead.com", super_admin: true)
    @community = Community.create!(name: @client_name, permalink: 'my')
    @schema = @community.schema
    @phone_klass = @schema.klasses.create!(name: 'Phone', attrs_attributes: [
      name: 'number', type: 'String'
    ])
    @feature = @schema.features.find_by(name: 'Dynamic::Sms::Feature')
    @feature.options.detect {|o| o.name == 'phone_klass'}.update!(value: @phone_klass.id)
    @feature.update!(enabled: true)
    @schema.load

    @base_params = {
      sender: 'toto',
      phone_number: '+33605040302',
      message: 'coucou',
      state: 'created',
    }
    @history_klass_name = @feature.concerns.detect {|c| c.name == 'History'}.klass.name.split('::').last.underscore.pluralize
  end

  after(:each) do
    @schema.unload
  end

  describe 'webhook_url' do
    before(:each) do
      sign_in(@user)
      @sms_id = SecureRandom.uuid
      @webhook_url = %Q[#{ENV['DYNAMO_PROTOCOL']}://#{ENV['DYNAMO_HOST']}#{ "#{ENV['APP_PATH_PREFIX']}" if ENV['APP_PATH_PREFIX']}/api/d/#{@client_name}/#{@history_klass_name}]

      stub_request(:post, "#{@base_url}/smses").with(
        body: @base_params.merge(
          id: @sms_id,
          client_name: @client_name,
          webhook_url: @webhook_url,
        )
      ).to_return(
        body: {
          state: 'ordered'
        }.to_json,
        status: 200
      )
      @date = DateTime.current
      @history_params = {
        base: {
          message_id: @sms_id,
          state: 'delivered',
          event_date: @date,
          event_description: 'marked as spam',
        }
      }
      D::My::Sms.create(@base_params.merge(id: @sms_id))
    end

    it 'should associate histories from service to sms' do
      post @webhook_url, params: @history_params
      expect(D::My::Sms.last.histories.count).to eq(1)
      expect(D::My::Sms.last.histories.first).to have_attributes(
        state: 'delivered',
        event_description: 'marked as spam',
      )
    end

    it 'should update the sms state' do
      expect{
        post @webhook_url, params: @history_params
      }.to change{
        D::My::Sms.last.state
      }.from('ordered').to('delivered')
    end

  end

  describe 'history_from_api' do
    before(:each) do
      response_get = {
        state: 'ordered',
        event_date: '2023-01-13T11:04:02.075Z',
        event_description: 'No error spotted',
      }
      stub_request(:get, "#{@base_url}/smses/#{@id}/histories?client_name=#{@client_name}").to_return({status: 200, body: response_get.to_json})
      D::My::Sms.skip_callback(:commit, :after, :sync_create)
      D::My::Sms.create!(@base_params.merge(id: @id))
    end

    it "should update the status via sync_update" do
      current_history = D::My::Sms.first.histories.create({
        state: 'created',
        event_date: '2023-01-13T11:04:02.075Z',
        event_description: 'No error spotted',
      })
      expect(current_history[:state]).to eq('created')
    end

  end # end of describe history_from_api

  describe 'histories_from_api' do
    before(:each) do
      D::My::Sms.skip_callback(:commit, :after, :sync_create)
      D::My::Sms.create!(@base_params.merge(id: @id))
      @history_response = {
        sms_id: @id,
        state: 'ordered',
        event_date: '2022-01-13T11:04:02.075Z',
        event_description: 'No error spotted',
      }
    end

    context 'when sms_id is passed' do
      before(:each) do
        response_array = []
        response_array2 = []
        @array_count = D::My::SmsHistory::LIMIT_NUMBER_OF_HISTORIES_FROM_API
        @array_count2 = 34

        @array_count.times {response_array.push(@history_response)}
        @array_count2.times {response_array2.push(@history_response)}

        url = "#{@base_url}/smses/#{@history_response[:sms_id]}/histories?client_name=#{@client_name}"
        stub_request(:get, url).to_return({status: 200, body: response_array.to_json})
        url2 = "#{@base_url}/smses/#{@history_response[:sms_id]}/histories?client_name=#{@client_name}&previous_page_last=#{response_array[-1][:sms_id]}"
        stub_request(:get, url2).to_return({status: 200, body: response_array2.to_json})
      end

      it 'should return histories with the same sms_id' do
        current_history = D::My::Sms.first.histories.create({
          state: 'created',
          event_date: '2023-01-13T11:04:02.075Z',
          event_description: 'No error spotted',
        })
        res = D::My::SmsHistory.histories_from_api(@id)
        expect(res.count).to eq(@array_count + @array_count2)
        res.each do |element|
          expect(element['sms_id']).to eq(current_history.message_id)
        end
      end

    end # end of context when sms_id is passed

    context 'when sms_id and dates are passed' do
      before(:each) do
        @start_d = '2021-12-31'
        @end_d = '2022-12-31'
        response_get = []
        2.times {response_get.push(@istory_response)}
        url_date = "#{@base_url}/smses/#{@id}/histories?client_name=#{@client_name}&start_date=#{@start_d}&end_date=#{@end_d}"
        stub_request(:get, url_date).to_return({status: 200, body: response_get.to_json})
      end

      it 'should accept dates as parameters' do
        response_body = D::My::SmsHistory.histories_from_api(@id, nil, @start_d, @end_d)
        response_body.each do |element|
          expect(element['event_date']).to be_between(@start_d, @end_d).inclusive
        end
      end

    end # end of context when sms_id and dates are passed

    context 'when a limit is passed' do
      before(:each) do
        @limit = 10
        response_get = []
        @limit.times do
          response_get.push({
            sms_id: SecureRandom.uuid,
            state: 'ordered',
            event_date: '2022-01-13T11:04:02.075Z',
            event_description: 'No error spotted',
          })
        end
        url = "#{@base_url}/smses/histories?client_name=#{@client_name}&limit=#{@limit}"
        stub_request(:get, url).to_return({status: 200, body: response_get.to_json})
      end

      it 'should get a limited amount of histories' do
        response_body = D::My::SmsHistory.histories_from_api(nil, @limit)
        expect(response_body.count).to eq(@limit)
      end

    end # end of context when a limit is passed

    context 'when sms_id, dates and a limit are passed' do
      before(:each) do
        response_get = []
        @limit = 23
        @start_d = Time.current - 1.year
        @end_d = Time.current
        @start_d_str = @start_d.strftime("%F")
        @end_d_str = @end_d.strftime("%F")
        rand_time = Time.at(@start_d + rand * (@end_d.to_r - @start_d.to_r))
        @limit.times do
          response_get.push(@history_response.merge(
            {event_date: rand_time.strftime("%F")}
          ))
        end
        url = "#{@base_url}/smses/#{@id}/histories?client_name=#{@client_name}&limit=#{@limit}&start_date=#{@start_d_str}&end_date=#{@end_d_str}"
        stub_request(:get, url).to_return({status: 200, body: response_get.to_json})
      end

      it 'should retrieve the right amout' do
        response_body = D::My::SmsHistory.histories_from_api(@id, @limit, @start_d_str, @end_d_str)
        expect(response_body.count).to be <= @limit
      end

      it 'should get histories between dates' do
        response_body = D::My::SmsHistory.histories_from_api(@id, @limit, @start_d_str, @end_d_str)
        response_body.each do |element|
          expect(element['event_date']).to be_between(@start_d, @end_d).inclusive
        end
      end

      it 'should get histories link to sms_id' do
        response_body = D::My::SmsHistory.histories_from_api(@id, @limit, @start_d_str, @end_d_str)
        response_body.each do |element|
          expect(element['sms_id']).to eq(@id)
        end
      end

    end # end of context when sms_id, dates and a limit are passed

  end # end of describe histories_from_api

  describe 'synchronize_with_api' do
    before(:each) do
      D::My::Sms.skip_callback(:commit, :after, :sync_create)
      D::My::Sms.create!(@base_params.merge(id: @id))
      10.times {D::My::Sms.first.histories.create({
        state: 'ordered',
        event_date: '2023-01-13T11:04:02.075Z',
        event_description: 'No error spotted',
      })}
      @history = D::My::SmsHistory.last
    end

    context 'when api has new histories' do

      it 'should insert the right attributes' do
        response = [{
          id: SecureRandom.uuid,
          state: 'sent',
          event_description: 'No Error',
          event_date: '2022-12-31T11:04:02.075Z',
        }]
        stub_request(:get, "#{@base_url}/smses/histories?client_name=#{@client_name}").to_return({body: response.to_json, status: 200})
        D::My::SmsHistory.synchronize_with_api

        expect(D::My::SmsHistory.find(response[0][:id])).to have_attributes(
          state: response[0][:state],
          event_description: response[0][:event_description],
          event_date: DateTime.parse(response[0][:event_date]),
        )
      end

      context 'and an id and dates are passed' do
        before(:each) do
          @start_d = '2022-12-31'
          @end_d = '2023-01-31'
          @response = [{
            id: SecureRandom.uuid,
            state: @history.state,
            event_description: @history.event_description,
            event_date: @history.event_date,
          }]
          url_date = "#{@base_url}/smses/#{@id}/histories?client_name=#{@client_name}&start_date=#{@start_d}&end_date=#{@end_d}"
          stub_request(:get, url_date).to_return({body: @response.to_json, status: 200})
        end

        it 'should retrieve histories from this sms between those dates' do
          D::My::SmsHistory.synchronize_with_api(@id, @start_d, @end_d)
          expect(D::My::SmsHistory.last(2)[0].id).to eq(@history.id)
          expect(D::My::SmsHistory.last.id).to eq(@response[0][:id])
          expect(D::My::SmsHistory.all.count).to eq(11)  # 10 from before(:each), 1 from stub
        end

      end # end of context and dates are passed

      context 'and a message_id is passed' do
        before(:each) do
          stub_request(:get, "#{@base_url}/smses/#{@id}/histories?client_name=#{@client_name}").to_return(
            {
              body: [{
                id: SecureRandom.uuid,
                state: 'ordered',
                event_date: '2023-01-13T11:04:02.075Z',
                event_description: 'No error spotted',
              }].to_json,
              status: 200
            }
          )
        end

        it 'should add missing histories linked to this sms' do
          D::My::SmsHistory.synchronize_with_api(@id)
          expect(D::My::SmsHistory.all.count).to eq(11) # 10 from before(:each), 1 from stub
        end

      end # end of context and message_id is passed

      context 'and no parameters are passed' do
        before(:each) do
          stub_request(:get, "#{@base_url}/smses/histories?client_name=#{@client_name}").to_return(
            {
              body: [
                {
                  id: SecureRandom.uuid,
                  state: 'ordered',
                  event_date: '2023-01-13T11:04:02.075Z',
                  event_description: 'No error spotted',
                },
                {
                  id: SecureRandom.uuid,
                  state: 'sent',
                  event_date: '2023-01-14T11:04:02.075Z',
                  event_description: 'No error spotted',
                }
              ].to_json,
              status: 200
            }
          )
        end

        it 'should add all missing histories' do
          D::My::SmsHistory.synchronize_with_api
          expect(D::My::SmsHistory.all.count).to eq(12) # 10 from before(:each), 2 from stub
        end

      end # end of context and no parameters are passed

    end # end of context when api has new smses

    context 'when api has no new histories' do
      before(:each) do
        stub_request(:get, "#{@base_url}/smses/histories?client_name=#{@client_name}").to_return(
          {
            body: [{
              id: @history.id,
              state: @history.state,
              event_description: @history.event_description,
              event_date: @history.event_date,
            }].to_json,
            status: 200
          }
        )
      end

      it 'should not add histories already present' do
        D::My::SmsHistory.synchronize_with_api
        expect(D::My::SmsHistory.last.id).to eq(@history.id)
        expect(D::My::SmsHistory.all.count).to eq(10) # 10 from before(:each)
      end

    end # end of context when api has no new smses

  end # end of describe synchronize_with_api

end
