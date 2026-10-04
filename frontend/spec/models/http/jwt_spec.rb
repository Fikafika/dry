describe 'HTTP::Jwt', type: :system do
  before(:each) do
    @token = 'd1007fc321be4d29a57f0eecd117a28c5a47159fe7867e4c7a6e747f4183dcc3' # this is enough for this test
    page_exec do
      @token = 'd1007fc321be4d29a57f0eecd117a28c5a47159fe7867e4c7a6e747f4183dcc3'
    end
  end

  def make_api_request_with_block
    page_exec do
      $result = HttpWithCrossDomain.get('http://some-api.dev.localhost/search', jwt_url: "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}") do |response|
        $response = response
        Element.find('.router-top-level').add_class('done')
      end
    end
    find('.done', visible: false)
  end

  def make_api_request_without_block
    page_exec do
      $result = HttpWithCrossDomain.get('http://some-api.dev.localhost/search', jwt_url: "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}")
      $result.then do |response|
        $response = response
        $failure = nil
      end
      $result.fail do |response|
        $response = nil
        $failure = response
      end
      $result.always do
        Element.find('.router-top-level').add_class('done')
      end
    end
    find('.done', visible: false)
  end

  def registry_requests
    page_eval do
      WebMock::RequestRegistry.instance.requested_signatures.map do |request_signature, times_executed|
        "#{request_signature.method} #{request_signature.uri} #{times_executed}"
      end.join(' ')
    end
  end

  def current_jwt_token
    page_eval do
      User.current.jwts["#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}"].to_n
    end
  end

  context 'without jwt_url option' do
    before(:each) do
      page_exec do
        stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
          { status: 200 }
        end
      end
    end

    it 'with block' do
      page_exec do
        $result = HttpWithCrossDomain.get('http://some-api.dev.localhost/search') do |response|
          Element.find('.router-top-level').add_class('done')
          $response = response
        end
      end
      find('.done', visible: false)
      expect(registry_requests).to eq([
        'GET http://some-api.dev.localhost/search 1',
      ].join(' '))
      expect(page_eval{$result.class.to_s}).to eq('HttpWithCrossDomain')
      expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
      expect(page_eval{$response.status_code}).to eq(200)
    end

    it 'without block' do
      page_exec do
        $result = HttpWithCrossDomain.get('http://some-api.dev.localhost/search')
        $result.then do |response|
          $response = response
          $failure = nil
        end
        $result.fail do |response|
          $response = nil
          $failure = response
        end
        $result.always do
          Element.find('.router-top-level').add_class('done')
        end
      end
      expect(registry_requests).to eq([
        'GET http://some-api.dev.localhost/search 1',
      ].join(' '))
      expect(page_eval{$result.class.to_s}).to eq('Promise')
      expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
      expect(page_eval{$response.status_code}).to eq(200)
    end
  end

  context 'when user is not connected' do
    before(:each) do
      page_exec do
        stub_request(:get, '/api/user').to_return do |request|
          { status: 404 }
        end
      end
    end

    context 'when first JWT is needed' do
      context 'and succeeds' do
        before(:each) do
          page_exec do
            stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
              { status: 201, body: @token }
            end
          end
        end

        context 'and API request succeeds' do
          before(:each) do
            page_exec do
              stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                if request.headers['authorization'] == "Bearer #{@token}"
                  { status: 200 }
                else
                  { status: 401 }
                end
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(200)
            expect(current_jwt_token).to eq(@token)
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(200)
            expect(current_jwt_token).to eq(@token)
          end
        end
      end
    end
  end

  context 'when user is connected' do
    before(:each) do
      page_exec do
        stub_request(:get, '/api/user').to_return do |request|
          { status: 200, body: { email: 'user@kosmopolead.com' }.to_json }
        end
      end
    end

    context 'when first JWT is needed' do
      context 'and succeeds' do
        before(:each) do
          page_exec do
            stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
              { status: 201, body: @token }
            end
          end
        end

        context 'and API request succeeds' do
          before(:each) do
            page_exec do
              stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                if request.headers['authorization'] == "Bearer #{@token}"
                  { status: 200 }
                else
                  { status: 401 }
                end
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(200)
            expect(current_jwt_token).to eq(@token)
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(200)
            expect(current_jwt_token).to eq(@token)
          end
        end

        context 'and API request fails' do
          before(:each) do
            page_exec do
              stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                if request.headers['authorization'] == "Bearer #{@token}"
                  { status: 422 }
                else
                  { status: 401 }
                end
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(422)
            expect(current_jwt_token).to eq(@token)
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$failure.status_code}).to eq(422)
            expect(current_jwt_token).to eq(@token)
          end
        end
      end

      context 'and fails' do
        context 'due to 401' do
          before(:each) do
            page_exec do
              stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
                { status: 401 }
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(401)
            expect(current_jwt_token).to be_nil
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$failure.status_code}).to eq(401)
            expect(current_jwt_token).to be_nil
          end
        end

        context 'due to 403' do
          before(:each) do
            page_exec do
              stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
                { status: 403 }
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(403)
            expect(current_jwt_token).to be_nil
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$failure.status_code}).to eq(403)
            expect(current_jwt_token).to be_nil
          end
        end
      end
    end

    context 'when there is already a stored token' do
      before(:each) do
        @old_token =  '80ac6cc29d9fd004d7b792ee679ee84558509e56f8a6d06803b415d6f2b13ab5'
        page_exec do
          @old_token =  '80ac6cc29d9fd004d7b792ee679ee84558509e56f8a6d06803b415d6f2b13ab5'
          User.current.jwts["#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}"] = @old_token # TODO generic method
        end
      end

      context 'when the token is valid' do
        context 'and API request succeeds' do
          before(:each) do
            page_exec do
              stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                if request.headers['authorization'] == "Bearer #{@old_token}"
                  { status: 200 }
                else
                  { status: 401 }
                end
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(200)
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(200)
          end
        end

        context 'and API request fails' do
          before(:each) do
            page_exec do
              stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                if request.headers['authorization'] == "Bearer #{@old_token}"
                  { status: 422 }
                else
                  { status: 401 }
                end
              end
            end
          end

          it 'with block' do
            make_api_request_with_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
            expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$response.status_code}).to eq(422)
          end

          it 'without block' do
            make_api_request_without_block
            expect(registry_requests).to eq([
              'GET /api/user.json 1',
              'GET http://some-api.dev.localhost/search 1',
            ].join(' '))
            expect(page_eval{$result.class.to_s}).to eq('Promise')
            expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
            expect(page_eval{$failure.status_code}).to eq(422)
          end
        end
      end

      context 'when the token has expired' do
        context 'and second token creation succeeds' do
          before(:each) do
            page_exec do
              stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
                { status: 201, body: @token }
              end
            end
          end

          context 'and API request succeeds' do
            before(:each) do
              page_exec do
                stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                  if request.headers['authorization'] == "Bearer #{@token}"
                    { status: 200 }
                  else
                    { status: 401 }
                  end
                end
              end
            end

            it 'with block' do
              make_api_request_with_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
                'GET http://some-api.dev.localhost/search 1',
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
              expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$response.status_code}).to eq(200)
              expect(current_jwt_token).to eq(@token)
            end

            it 'without block' do
              make_api_request_without_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
                'GET http://some-api.dev.localhost/search 1',
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('Promise')
              expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$response.status_code}).to eq(200)
              expect(current_jwt_token).to eq(@token)
            end
          end

          context 'and API request fails' do
            before(:each) do
              page_exec do
                stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                  if request.headers['authorization'] == "Bearer #{@token}"
                    { status: 422 }
                  else
                    { status: 401 }
                  end
                end
              end
            end

            it 'with block' do
              make_api_request_with_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
                'GET http://some-api.dev.localhost/search 1',
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
              expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$response.status_code}).to eq(422)
              expect(current_jwt_token).to eq(@token)
            end

            it 'without block' do
              make_api_request_without_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
                'GET http://some-api.dev.localhost/search 1',
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('Promise')
              expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$failure.status_code}).to eq(422)
              expect(current_jwt_token).to eq(@token)
            end
          end
        end

        context 'and second token creation fails' do
          before(:each) do
            page_exec do
              stub_request(:get, 'http://some-api.dev.localhost/search').to_return do |request|
                if request.headers['authorization'] == "Bearer #{@token}"
                  { status: 200 }
                else
                  { status: 401 }
                end
              end
            end
          end

          context 'due to 401' do
            before(:each) do
              page_exec do
                stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
                  { status: 401 }
                end
              end
            end

            it 'with block' do
              make_api_request_with_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
              expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$response.status_code}).to eq(401)
              expect(current_jwt_token).to eq(@old_token)
            end

            it 'without block' do
              make_api_request_without_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('Promise')
              expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$failure.status_code}).to eq(401)
              expect(current_jwt_token).to eq(@old_token)
            end
          end

          context 'due to 403' do
            before(:each) do
              page_exec do
                stub_request(:post, "#{`UneekSso.url`}/jwt?service=#{`window.encodeURIComponent(#{'http://some-api.dev.localhost/search'})`}").to_return do |request|
                  { status: 403 }
                end
              end
            end

            it 'with block' do
              make_api_request_with_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('HTTP::Jwt::JwtRequestSequence')
              expect(page_eval{$response.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$response.status_code}).to eq(403)
              expect(current_jwt_token).to eq(@old_token)
            end

            it 'without block' do
              make_api_request_without_block
              expect(registry_requests).to eq([
                'GET /api/user.json 1',
                'GET http://some-api.dev.localhost/search 1',
                "POST #{ENV['UNEEK_SSO_PROTOCOL']}://#{ENV['UNEEK_SSO_HOST']}/jwt?#{{ 'service' => 'http://some-api.dev.localhost/search' }.to_query} 1",
              ].join(' '))
              expect(page_eval{$result.class.to_s}).to eq('Promise')
              expect(page_eval{$failure.class.to_s}).to eq('HttpWithCrossDomain')
              expect(page_eval{$failure.status_code}).to eq(403)
              expect(current_jwt_token).to eq(@old_token)
            end
          end
        end
      end
    end
  end
end
