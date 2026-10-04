require 'securerandom'

describe Dynamic::Sms::Sms, elasticsearch: false, sidekiq: false do
  before(:each) do
    @base_url = "#{ENV['SMS_API_PROTOCOL']}://#{ENV['SMS_API_HOST']}#{":#{ENV['SMS_API_PORT']}" if ENV['SMS_API_PORT']}"
    @client_name = 'My'
    @schema = Dynamic::Schema.create!(name: @client_name)
    @feature = @schema.features.find_by(name: 'Dynamic::Sms::Feature')
    @phone_klass = @schema.klasses.create!(name: 'Phone', attrs_attributes: [
      name: 'number', type: 'String'
    ])
    @contact_klass = @schema.klasses.create!(name: 'Contact', attrs_attributes: [
      name: 'first_name', type: 'String'
    ])

    phone_owner = @phone_klass.associations.create(
      name: 'owner',
      type: 'BelongsTo',
      target_klass: @contact_klass,
    )
    contact_phones = @contact_klass.associations.create(
      name: 'phones',
      type: 'HasMany',
      target_klass: @phone_klass,
      inverse_of: phone_owner,
    )

    phone_owner.update(inverse_of: contact_phones)
    @feature.options.detect {|o| o.name == 'phone_klass'}.update!(value: @phone_klass.id)
  end

  after(:each) do
    @schema.unload
  end

  describe '.create' do
    before(:each) do
      @user = User.create(last_name: 'toto', first_name: 'titi')
      @params = {
        id: SecureRandom.uuid,
        sender: 'toto',
        message: 'coucou',
        disable_sms_sync: true,
      }
      User.current = @user
      @feature.update!(enabled: true)
      @schema.load
    end

    it 'should assign state "sent" by default' do
      expect(D::My::Sms.create!(@params.merge(phone_number: '+33605040302')).state).to eq('sent')
    end

    it 'should assign state "created" when create_as_draft is specified' do
      expect(D::My::Sms.create!(@params.merge(phone_number: '+33605040302', create_as_draft: true)).state).to eq('created')
    end

    it 'should raise error on empty phone number' do
      expect{D::My::Sms.create!(phone: @phone, message: 'coucou', sender: 'toto', disable_sms_sync: true)}.to raise_error{ActiveRecord::RecordInvalid}
    end

    it 'should raise error on empty message' do
      expect{D::My::Sms.create!(phone: @phone, phone_number: '+33612345678', sender: 'toto', disable_sms_sync: true)}.to raise_error{ActiveRecord::RecordInvalid}
    end

    it 'should raise error on empty sender' do
      expect{D::My::Sms.create!(phone: @phone, message: 'coucou', phone_number: '+33612345678', disable_sms_sync: true)}.to raise_error{ActiveRecord::RecordInvalid}
    end

  end # end of describe default values on create

  describe '.create_sms_api' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
      @webhook_url = "http://dynamo.dev.localhost/crm/api/d/#{@client_name}/histories"
      @params = {
        id: SecureRandom.uuid,
        sender: 'toto',
        phone_number: '+33605040302',
        message: 'coucou',
        state: 'created',
        webhook_url: @webhook_url
      }
      @expected_res = {
        state: 'created',
        sender: 'toto',
        message: 'coucou',
        client_name: @client_name,
      }.merge!(@params)
      stub_request(:post, "#{@base_url}/smses").with(
        body: @params.merge(client_name: @client_name)
      ).to_return({body: @expected_res.to_json, status: 200})
    end

    it 'should return a hash with its attributes' do
      expect(D::My::Sms.create_sms_api(@params)).to eq(@expected_res.stringify_keys)
    end

    it 'should add a webhook_url and a client_name to the request body' do
      D::My::Sms.create_sms_api(@params)
      expect(a_request(:post, "#{@base_url}/smses").with( body: @params.merge(client_name: @client_name) )).to have_been_made
    end

  end # end of describe create_sms_api

  describe '.sync_create' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load

      @params = {
        id: SecureRandom.uuid,
        sender: 'toto',
        phone_number: '+33605040302',
        message: 'coucou',
        state: 'created',
      }
      @webhook_url = %Q[#{ENV['DYNAMO_PROTOCOL']}://#{ENV['DYNAMO_HOST']}#{ "#{ENV['APP_PATH_PREFIX']}" if ENV['APP_PATH_PREFIX']}/api/d/#{@client_name}/sms_histories]

      stub_request(:post, "#{@base_url}/smses").with(
        body: @params.merge(
          client_name: @client_name,
          webhook_url: @webhook_url
        )
      ).to_return(body: {state: 'ordered'}.to_json, status: 200)

      D::My::Sms.create!(@params)
    end

    it "should create webhook_url from schema name and SmsHistory klass' permalink" do
      expect(a_request(:post, "#{@base_url}/smses").with(
        body: @params.merge(
          client_name: @client_name,
          webhook_url: @webhook_url
        )
      )).to have_been_made.once
    end

  end # end of describe sync_create

  describe '.sms_from_api' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
      @id = '07081a6e-f666-43a9-ba5c-ab4a20a6bf57'
      @stub_sms = {
        id: @id,
        sender:'toto',
        phone_number: '+33605040302',
        message: 'coucou lézami',
        state: 'created',
        updated_at: '2023-01-11T11:04:02.075Z',
      }
    end

    context 'with valid request' do
      before(:each) do
        url = "#{@base_url}/smses/#{@id}?client_name=#{@client_name}"
        stub_request(:get, url).to_return({body: @stub_sms.to_json, status: 200})
      end

      it 'should respond with the same id' do
        res = D::My::Sms.sms_from_api(@stub_sms[:id])
        expect(res['id']).to eq(@stub_sms[:id])
      end

    end # end of context with valid request

  end # end of describe sms_from_api

  describe '.smses_from_api' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
      @sms_response = {
        sender:'toto',
        phone_number: '+33605040302',
        message: 'coucou lézami',
        state: 'created',
        updated_at: '2023-01-11T11:04:02.075Z',
      }
    end

    context 'without arguments' do
      before(:each) do
        @id_dummy = '07081a6e-f666-43a9-ba5c-ab4a20a6bf57'
        @id_dummy2 = '07081a6e-f666-43a9-ba5c-ab4a20a6bf58'
        @smses1_count = 100
        @smses2_count = 63
        @smses1 = []
        @smses2 = []
        @smses1_count.times {@smses1.push( @sms_response.merge({id: @id_dummy}) )}
        @smses2_count.times {@smses2.push( @sms_response.merge({id: @id_dummy2}) )}

        url1 = "#{@base_url}/smses?client_name=#{@client_name}"
        stub_request(:get, url1).to_return({body: @smses1.to_json, status: 200})
        url2 = "#{@base_url}/smses?client_name=#{@client_name}&previous_page_last=#{@id_dummy}"
        stub_request(:get, url2).to_return({body: @smses2.to_json, status: 200})
      end

      it 'should retrieve an array with all smses' do
        smses_result = D::My::Sms.smses_from_api
        expect(smses_result).to be_a Array
        expect(smses_result.count).to eq(@smses1_count + @smses2_count)
      end

    end # end of context without arguments

    context 'when a limit is passed' do
      before(:each) do
        @limit = 10
        response_get = []
        @limit.times {response_get.push(@sms_response)}
        url = "#{@base_url}/smses?client_name=#{@client_name}&limit=#{@limit}"
        stub_request(:get, url).to_return({status: 200, body: response_get.to_json})
      end

      it 'should get a limited amount of smses' do
        res = D::My::Sms.smses_from_api(@limit)
        expect(res.count).to eq(@limit)
      end

    end # end of context when a limit is passed

    context 'when dates and a limit are passed' do
      before(:each) do
        @start_d = Time.current - 1.year
        @end_d = Time.current
        @start_d_str = @start_d.strftime("%F")
        @end_d_str = @end_d.strftime("%F")
        @limit = 23
        response_get = []
        rand_time = Time.at(@start_d + rand * (@end_d.to_r - @start_d.to_r))
        @limit.times do
          response_get.push(@sms_response.merge({event_date: rand_time.strftime("%F")}))
        end
        url = "#{@base_url}/smses?client_name=#{@client_name}&limit=#{@limit}&start_date=#{@start_d_str}&end_date=#{@end_d_str}"
        stub_request(:get, url).to_return({status: 200, body: response_get.to_json})
      end

      it 'should retrieve the right amout' do
        res = D::My::Sms.smses_from_api(@limit, @start_d_str, @end_d_str)
        expect(res.count).to be <= @limit
      end

      it 'should get histories between dates' do
        res = D::My::Sms.smses_from_api(@limit, @start_d_str, @end_d_str)
        res.each {|element| expect(element['event_date']).to be_between(@start_d, @end_d).inclusive}
      end

    end # end of context when dates and a limit are passed

    context 'error from api (422)' do
      before(:each) do
        url = "#{@base_url}/smses?client_name=#{@client_name}"
        stub_request(:get, url).to_return({status: 422})
      end

      it 'should return empty array' do
        res = D::My::Sms.smses_from_api
        expect(res).to eq([])
      end
    end

    context 'api return empty array' do
      before(:each) do
        url = "#{@base_url}/smses?client_name=#{@client_name}"
        stub_request(:get, url).to_return({status: 200, body: [].to_json})
      end

      it 'should return empty array' do
        res = D::My::Sms.smses_from_api
        expect(res).to eq([])
      end
    end

  end # end of describe smses_from_api

  describe '.sync_update' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
      @id = '07081a6e-f666-43a9-ba5c-ab4a20a6bf57'
    end

    before(:each) do
      url_post = "#{@base_url}/smses"
      url_get = "#{@base_url}/smses/#{@id}?client_name=#{@client_name}"
      stub_request(:post, url_post).to_return({
        body: {
          sender: 'toto',
          phone_number: '33605040302',
          message: 'coucou',
          tag: 'test',
          state: 'created',
          client_name: @client_name,
          client_webhook_url: "http://myspecial.url",
        }.to_json,
        status: 200
      })
      stub_request(:get, url_get).to_return({
        body: {
          id: @id,
          sender: 'toto',
          phone_number: '+33605040302',
          message: 'coucou lézami',
          state: 'ordered',
          updated_at: '2023-01-13T11:04:02.075Z',
        }.to_json,
        status: 200
      })
    end

    it 'should pass with stub get' do
      current_sms = D::My::Sms.create({
        sender: 'toto',
        phone_number: '+33605040302',
        message: 'coucou lézami',
        state: 'created',
        id: @id,
        disable_sms_sync: true,
      })
      expect{current_sms.sync_update}.to_not raise_exception
      expect(current_sms[:state]).to eq('ordered')
    end

  end # end of describe sync_update

  describe '.synchronize_with_api' do
    before(:each) do
      @feature.update!(enabled: true)
      @id = SecureRandom.uuid
      @schema.load
      @sms_hash = {
        sender: 'toto',
        phone_number: '+33605040302',
        message: 'hello',
        state: 'created',
        updated_at: '2023-01-11T11:04:02.075Z',
        disable_sms_sync: true,
      }
      stub_request(:post, "#{@base_url}/smses").to_return({
        body: {
          sender: 'toto',
          phone_number: '33605040302',
          message: 'coucou',
          tag: 'test',
          state: 'created',
          client_name: @client_name,
          client_webhook_url: "http://myspecial.url",
        }.to_json,
        status: 200
      })
      10.times {D::My::Sms.create(@sms_hash)}
    end

    context 'when api has new smses' do
      before(:each) do
        stub_request(:get, "#{@base_url}/smses?client_name=#{@client_name}").to_return({
          body: [{
            id: SecureRandom.uuid,
            sender: 'toto',
            phone_number: '+33605040302',
            message: 'coucou lézami',
            state: 'created',
            tag: 'FirstMessage',
            updated_at: '2023-01-11T11:04:02.075Z',
          }].to_json,
          status: 200
        })
      end

      it 'should add missing smses' do
        expect{
          D::My::Sms.synchronize_with_api
        }.to change{
          D::My::Sms.all.count
        }.from(10).to(11) # 10 from before(:each), 1 from stub request
      end

      it 'should add missing smses with their values' do
        expect{
          D::My::Sms.synchronize_with_api
        }.to change {
          D::My::Sms.last.message
        }.from('hello').to('coucou lézami')
      end

      context 'and dates are passed' do
        before(:each) do
          @start_d = '2022-12-31'
          @end_d = '2023-01-31'
          url = "#{@base_url}/smses?client_name=#{@client_name}&start_date=#{@start_d}&end_date=#{@end_d}"
          stub_request(:get, url).to_return({
            body: [{
              id: @id,
              sender: @sms_hash[:sender],
              phone_number: @sms_hash[:phone_number],
              message: @sms_hash[:message],
              state: @sms_hash[:state],
              updated_at: @sms_hash[:updated_at],
            }].to_json,
            status: 200
          })
        end

        it 'should retrieve smses between those dates' do
          expect{
            D::My::Sms.synchronize_with_api(@start_d, @end_d)
          }.to change {
            D::My::Sms.all.count
          }.from(10).to(11) # 10 from before(:each), 1 from stub request
        end

      end # end of context when dates are passed

    end # end of context when api has new smses

    context 'when api has no new smses' do

      before(:each) do
        stub_request(:get, "#{@base_url}/smses?client_name=#{@client_name}").to_return({
          body: [{
            id: D::My::Sms.last.id,
            sender: @sms_hash[:sender],
            phone_number: @sms_hash[:phone_number],
            message: @sms_hash[:message],
            state: @sms_hash[:state],
            updated_at: @sms_hash[:updated_at],
          }].to_json, status: 200
        })
      end

      it 'should not add smses already present' do
        expect{
          D::My::Sms.synchronize_with_api
        }.to_not change{
          D::My::Sms.all.count
        }
      end

    end # end of context when api has no new smses

  end # end of describe synchronize_with_api

end
