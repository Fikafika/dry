module Dynamic
  module Sms
    module History; extend ActiveSupport::Concern

      LIMIT_NUMBER_OF_HISTORIES_FROM_API = 100

      included do
        after_commit :update_sms, on: :create

        def update_sms
          self.message.update(state: self.state) if self.message
        end

        def sync_update
          response_body = self.class.history_from_api(self.sms_id)
          self.update({'state' => response_body['state']}) if response_body['state']
        end
      end

      class_methods do

        def history_from_api(sms_id)
          response_body = Dynamic::Sms.call_api(
            "#{Dynamic::Sms::URI_SMS_API}/#{sms_id}/histories",
            {client_name: self.module_parent.name.demodulize},
            {content_type: 'application/json'}
          )
          return response_body
        end

        def histories_from_api(sms_id = nil, limit = nil, start_date = nil, end_date = nil)
          url = Dynamic::Sms::URI_SMS_API
          url += sms_id ? "/#{sms_id}/histories" : "/histories"
          params = {}

          params[:client_name] = self.module_parent.name.demodulize
          params[:limit] = limit if limit
          params[:start_date] = start_date if start_date
          params[:end_date] = end_date if end_date

          histories = Dynamic::Sms.call_api(url, params, {content_type: 'application/json'})
          return [] unless histories.any?
          batch_count = histories.count

          until batch_count < LIMIT_NUMBER_OF_HISTORIES_FROM_API
            params[:previous_page_last] = histories[-1]['sms_id']
            current_count = histories.count
            next_histories = Dynamic::Sms.call_api(url, params, {content_type: 'application/json'})
            break if next_histories&.last && next_histories.last['id'] == params[:previous_page_last] # Same batch as previous one
            histories = histories + next_histories
            batch_count = histories.count - current_count
          end

          return histories
        end

        def synchronize_with_api(sms_id = nil, start_date = nil, end_date = nil)
          histories_api = histories_from_api(sms_id, nil, start_date, end_date)
          histories_api = [histories_api] unless histories_api.is_a?(Array)
          histories_api.each do |history|
            self.create_with(
              message_id: history['message_id'],
              event_date: history['event_date'],
              event_description: history['event_description'],
              state: history['state'],
            ).find_or_create_by(id: history['id'])
          end
        end
      end
    end
  end
end
