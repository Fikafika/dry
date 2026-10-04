module Dynamic
  module MailHosting
    class SyncState < ActiveRecord::Base
      include Dynamic::Mount

      define_table do |t|
        t.datetime :last_sync_at
        t.string :last_message_id
        t.string :rules_signature
        t.text :cursor
      end

      MESSAGE_ASSOCIATION_MAPPING = {
        'sender' => 'sender',
        'recipients' => 'recipients',
        'carbon_copy' => 'cc',
        'blind_carbon_copy' => 'bcc',
      }.freeze

      DEFAULT_STR_SYNC_DATETIME = '1970-01-01T00:00:00Z'.freeze

      CORRESPONDENT_ADDRESS_ATTRIBUTE = 'email_address'.freeze

      def self.sync
        Dynamic::Schema.all.each do |schema|
          feature = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
          next unless feature&.enabled
          schema.load

          sync_state_klass = "D::#{schema.name}::R::MailHosting::SyncState".constantize
          message_klass = feature.concerns.detect{ |c| c.name == 'Message'}&.klass&.const
          next unless message_klass

          email_klass = Dynamic::MailHosting::Feature.email_schema_klass(feature)
          recipient_info_feature = schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
          unique_email_klass = recipient_info_feature.concerns.detect {|c| c.name == 'RecipientEmailAddress'}.klass.const
          communication_feature = schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
          email_concern = communication_feature.concerns.detect {|c| c.name == 'Email'}
          address_attr = email_concern.options.detect {|o| o.name == 'address_attribute'}.value.name

          sync_state = sync_state_klass.first_or_create!
          cursor = sync_state.cursor.presence
          synced_messages = false

          message_concern = feature.concerns.detect {|c| c.name == 'Message'}
          attr_mapping = self.attr_mapping(message_concern)
          assoc_mapping = self.assoc_mapping(message_concern)

          message_association_ids_by_field_name = {}
          message_concern.options.each do |o|
            next unless o.name.end_with?('_association')
            n = o.name.gsub('_association', '')
            message_association_ids_by_field_name[MESSAGE_ASSOCIATION_MAPPING[n]] = o.value.id
          end

          req = initialize_request(schema)
          columns_to_import = nil

          loop do
            body = fetch_messages(req, sync_state, cursor)
            pagination = body.delete('pagination')
            source_messages = body.values.flatten.uniq {|m| m['id']}
            break unless source_messages.any?

            messages = source_messages.map {|m| convert_message(m, attr_mapping, assoc_mapping)}
            columns_to_import ||= message_klass.dynamic_attribute_types.keys.intersection(messages.first.keys)

            message_klass.import(
              columns_to_import,
              messages,
              on_duplicate_key_update: {conflict_target: [:id]}
            )

            associate_messages_emails(feature, source_messages, message_klass, unique_email_klass, address_attr, message_association_ids_by_field_name)
            sync_state.update_sync_tracking_state(source_messages)

            synced_messages = true

            cursor = pagination ? pagination['next_cursor'] : nil
            break if cursor.blank?
            sync_state.update!(cursor: cursor)
          end

          current_signature = rules_signature_for_schema(schema)
          previous_signature = sync_state.rules_signature.to_s
          rules_changed = previous_signature == current_signature

          if synced_messages
            Dynamic::MailHosting::Worker::Attachment.perform_async(schema.id)
          end

          sync_state.update!(last_sync_at: Time.zone.now, cursor: nil, rules_signature: current_signature)
        end
      end

      def update_sync_tracking_state(source_messages)
        most_recent_message = source_messages.max_by do |message|
          sent_at = Time.zone.parse(message['sent_at'].to_s) rescue nil
          [sent_at || Time.zone.parse('1970-01-01T00:00:00Z'), message['id'].to_s]
        end
        return unless most_recent_message

        latest_sent_at = Time.zone.parse(most_recent_message['sent_at'].to_s) rescue nil

        self.last_sync_at = latest_sent_at || Time.zone.now
        self.last_message_id = most_recent_message['id'] if most_recent_message['id'].present?
        self.save!
      end

      private

      def self.initialize_request(schema)
        community = Community.find_by(schema: schema)
        return Faraday.new(
          url: "#{ENV['UNEEK_MAIL_APP_PROTOCOL']}://#{ENV['UNEEK_MAIL_APP_HOST']}/",
          params: { community_id: community.uneek_sso_uuid },
          headers: {'Content-Type' => 'application/json'}
        ) do |conn|
          conn.options.open_timeout = 5
          conn.options.timeout = 180
          conn.options.write_timeout = 30
          conn.request(:authorization, :basic, ENV['UNEEK_MAIL_APP_USERNAME'], ENV['UNEEK_MAIL_APP_PASSWORD'])
          conn.response(:json, content_type: /\bjson/)
        end
      end

      def self.associate_messages_emails(feature, messages, message_klass, unique_email_klass, address_attr, message_association_ids_by_field_name)
        message_association_ids_by_field_name.each do |field_name, assoc_id|
          emails_for_messages = {}
          messages.each do |message|
            next if message[field_name].blank? || message['id'].blank?

            value = message[field_name]
            emails = value.is_a?(Array) ? value : [value]
            addresses = emails.map { |email| email[CORRESPONDENT_ADDRESS_ATTRIBUTE] }.compact.uniq
            next if addresses.empty?

            emails_for_messages[message['id']] = addresses
          end
          next if emails_for_messages.empty?

          mail_addresses = emails_for_messages.values.flatten.uniq.compact
          ids_by_email = unique_email_klass.where(address_attr => mail_addresses).pluck(address_attr, 'id').to_h
          mail_addresses.each do |address|
            next if ids_by_email.has_key?(address)
            ids_by_email[address] = unique_email_klass.find_or_create_by(address_attr => address).id
          end
          next if ids_by_email.empty?

          # FIXME should create or update unique emails to trigger callbacks
          associations = []
          emails_for_messages.each do |message_id, addresses|
            addresses.each do |address|
              email_id = ids_by_email[address]
              next unless email_id

              associations << {
                association_owner_type: message_klass.name,
                association_owner_id: message_id,
                association_target_type: unique_email_klass.name,
                association_target_id: email_id,
                schema_association_type: 'Dynamic::Schema::Association::Base',
                schema_association_id: assoc_id,
              }
            end
          end
          next unless associations.any?
          feature.schema.const_assoc_klass.import(
            associations,
            on_duplicate_key_ignore: {
              conflict_target: [:id],
              columns: [
                :association_owner_type,
                :association_owner_id,
                :association_target_type,
                :association_target_id
              ]
            }
          )
        end
      end

      def self.convert_message(message, attr_mapping, assoc_mapping)
        allowed_source_keys = ['id'] + attr_mapping.keys + assoc_mapping.keys

        # FIXME iterate on message keys ?
        allowed_source_keys.each_with_object({}) do |source_key, result|
          value = message[source_key] || message[source_key.to_sym] # FIXME why both ?
          next if value.nil?

          target_key = attr_mapping[source_key] || source_key # FIXME why not using association_mapping as well ?
          result[target_key] = value
        end
      end

      def self.attr_mapping(message_concern)
        attr_mapping = {}
        Dynamic::MailHosting::Feature::MESSAGE_ATTRS_BY_NAME.each_key do |k|
          k_ = k.to_s
          opt = message_concern.options.detect {|o| o.name.start_with?(k_)}
          attr_mapping[k_] = opt.value&.name
        end
        return attr_mapping
      end

      def self.assoc_mapping(message_concern)
        assoc_mapping = {}
        Dynamic::MailHosting::Feature::MESSAGE_ASSOCS_BY_NAME.each_key do |k|
          k_ = k.to_s
          opt = message_concern.options.detect {|o| o.name.start_with?(k_)}
          assoc_mapping[k_] = opt.value&.name
        end
        return assoc_mapping
      end

      def self.rules_signature_for_schema(schema)
        rules_klass = "D::#{schema.name}::R::MailHosting::Rule".safe_constantize
        payload = rules_klass.order(:id).map do |rule|
          [
            rule.id,
            rule.name,
            rule.klass_name,
            rule.record_id,
            rule.conditions.order(:id).map { |condition| [condition.id, condition.attr, condition.operator, condition.value] }
          ]
        end
        Digest::SHA256.hexdigest(payload.to_json)
      end

      def self.fetch_messages(request, sync_state, cursor = nil)
        last_sync = sync_state.last_sync_at ? sync_state.last_sync_at.to_s : DEFAULT_STR_SYNC_DATETIME
        payload = {
          rules: {
            all_messages: {
              sent_at: {
                gt: [Time.zone.parse(last_sync).iso8601]
              }
            }
          },
          limit: 50,
        }
        payload[:cursor] = cursor if cursor.present?

        response = request.post('api/email/messages/filter', payload.to_json)

        unless response.success?
          raise StandardError, "MailHosting synchronization failed: status=#{response.status} body=#{response.body}"
        end

        response.body
      end

    end
  end
end
