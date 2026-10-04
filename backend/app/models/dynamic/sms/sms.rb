module Dynamic
  module Sms
    module Sms; extend ActiveSupport::Concern

      concerning :Sync do
        LIMIT_NUMBER_OF_SMS_FROM_API = 100

        included do
          attr_accessor :disable_sms_sync
          after_commit :sync_create, on: :create, unless: :disable_sms_sync

          def sync
            response_body = sms_from_api(self.id)
            response_body.any? ? sync_update : sync_create
          end

          def sync_create
            histories_klass_name = histories.klass.name.split('::').last.underscore.pluralize
            schema_name = self.class.name.split('::')[1]
            params = {
              id: self.id,
              sender: self.sender,
              phone_number: self.phone_number,
              message: self.message,
              state: self.state,
              webhook_url: %Q[#{ENV['DYNAMO_PROTOCOL']}://#{ENV['DYNAMO_HOST']}#{ "#{ENV['APP_PATH_PREFIX']}" if ENV['APP_PATH_PREFIX']}/api/d/#{schema_name}/#{histories_klass_name}],
            }
            response_body = self.class.create_sms_api(params)
            self.update({state: response_body['state']}) if response_body && response_body['state']
          end

          def sync_update
            response_body = self.class.sms_from_api(self.id)
            self.update({state: response_body['state']}) if response_body && response_body['state']
          end
        end

        class_methods do

          def create_sms_api(params)
            response_body = Dynamic::Sms.call_api(
              Dynamic::Sms::URI_SMS_API,
              params.merge(client_name: self.module_parent.name.demodulize),
              {type: :post, content_type: 'application/json'}
            )
            return response_body
          end

          def sms_from_api(sms_id)
            response_body = Dynamic::Sms.call_api(
              "#{Dynamic::Sms::URI_SMS_API}/#{sms_id}",
              {client_name: self.module_parent.name.demodulize},
              {content_type: 'application/json'}
            )
            return response_body
          end

          def smses_from_api(limit = nil, start_date = nil, end_date = nil)
            params = {client_name: self.module_parent.name.demodulize}
            params[:limit] = limit if limit
            params[:start_date] = start_date if start_date
            params[:end_date] = end_date if end_date

            smses = Dynamic::Sms.call_api(Dynamic::Sms::URI_SMS_API, params, {content_type: 'application/json'})
            return [] unless smses
            batch_count = smses.count

            until batch_count < LIMIT_NUMBER_OF_SMS_FROM_API
              params[:previous_page_last] = smses[-1]['id']
              current_count = smses.count
              next_smses = Dynamic::Sms.call_api(Dynamic::Sms::URI_SMS_API, params, {content_type: 'application/json'})
              break if next_smses&.last && next_smses.last['id'] == params[:previous_page_last] # Same batch as previous one
              smses = smses + next_smses
              batch_count = smses.count - current_count
            end

            return smses
          end

          def synchronize_with_api(start_date = nil, end_date = nil)
            smses_api = smses_from_api(nil, start_date, end_date)

            smses_api.each do |sms|
              create_options = self.create_with(
                sender: sms['sender'],
                phone_number: sms['phone_number'],
                message: sms['message'],
                state: sms['state'],
                disable_sms_sync: true,
              )
              create_options.find_or_create_by(id: sms['id'])
            end
          end
        end
      end

      concerning :State do
        included do
          attr_accessor :create_as_draft
          before_validation :assign_default_state
        end

        def assign_default_state
          return if self.state.present?
          self.state = create_as_draft ? 'created' : 'sent'
        end
      end

    end
  end
end
