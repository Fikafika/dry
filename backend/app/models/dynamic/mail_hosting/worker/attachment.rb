module Dynamic
  module MailHosting
    module Worker
      class Attachment
        include ::Sidekiq::Job

        sidekiq_options queue: :mail_hosting_sync

        def perform(schema_id)
          return if schema_id.blank?
          return if already_running_for?(schema_id)

          begin
            register_running_for(schema_id)

            schema = Dynamic::Schema.find_by(id: schema_id)
            return unless schema

            feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
            return unless feature&.enabled

            schema.load
            recompute_parent_associations_from_rules(feature)
          ensure
            deregister_running_for(schema_id)
          end
        end

        def recompute_parent_associations_from_rules(feature)
          message_concern = feature.concerns.detect {|c| c.name == 'Message'}
          @message_schema_klass = message_concern&.klass
          assoc_klass = feature.schema.const_assoc_klass
          return unless @message_schema_klass && assoc_klass

          message_klass = @message_schema_klass.const

          attr_mapping = Dynamic::MailHosting::SyncState.attr_mapping(message_concern)
          assoc_mapping = Dynamic::MailHosting::SyncState.assoc_mapping(message_concern)

          email_klass = Dynamic::MailHosting::Feature.email_schema_klass(feature)
          recipient_info_feature = feature.schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
          unique_email_klass = recipient_info_feature.concerns.detect {|c| c.name == 'RecipientEmailAddress'}.klass.const
          communication_feature = feature.schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
          email_concern = communication_feature.concerns.detect {|c| c.name == 'Email'}
          address_attr = email_concern.options.detect {|o| o.name == 'address_attribute'}.value.name

          message_association_ids_by_field_name = {}
          message_concern.options.each do |o|
            next unless o.name.end_with?('_association')
            n = o.name.gsub('_association', '')
            message_association_ids_by_field_name[Dynamic::MailHosting::SyncState::MESSAGE_ASSOCIATION_MAPPING[n]] = o.value.id
          end

          rules_klass = "D::#{feature.schema.name}::R::MailHosting::Rule".safe_constantize
          return unless rules_klass

          rules = rules_klass.includes(:conditions)
          return if rules.empty?

          reset_parent_message_associations_for_rules!(assoc_klass, rules)

          columns_to_import = nil

          rules.each do |rule|
            schema_association_id = schema_association_id_for_rule(rule)
            next unless schema_association_id

            rule.records_in_batches do |records|
              next if records.blank?

              messages_by_record = rule.messages_for(records, feature.schema)
              next unless messages_by_record.is_a?(Hash)

              source_messages = messages_by_record.values.flatten
              source_messages.uniq! {|message| message['id']}
              source_messages.compact!

              if source_messages.any?
                messages = source_messages.map {|message| Dynamic::MailHosting::SyncState.convert_message(message, attr_mapping, assoc_mapping)}
                if messages.any?
                  columns_to_import ||= message_klass.dynamic_attribute_types.keys.intersection(messages.first.keys)
                  message_klass.import(
                    columns_to_import,
                    messages,
                    on_duplicate_key_update: { conflict_target: [:id] }
                  )
                  Dynamic::MailHosting::SyncState.associate_messages_emails(feature, source_messages, message_klass, unique_email_klass, address_attr, message_association_ids_by_field_name)
                end
              end

              associations = message_associations_to_import(messages_by_record, rule, schema_association_id)
              next if associations.empty?

              valid_message_ids = message_klass.where(id: associations.map { |a| a[:association_target_id] }.uniq).pluck(:id)
              next if valid_message_ids.empty?

              valid_message_ids_lookup = valid_message_ids.each_with_object({}) { |id, hash| hash[id] = true }
              associations = associations.select { |row| valid_message_ids_lookup[row[:association_target_id]] }

              import_parent_message_associations!(assoc_klass, associations)
            end
          end
        end

        private

        # FIXME this does not guarantee to return the correct association
        def schema_association_id_for_rule(rule)
          rule_schema_klass = @message_schema_klass.schema.klasses.detect {|k| k.name == rule.klass_name.demodulize}
          schema_association = rule_schema_klass&.associations&.detect {|association| association.target_klass_id == @message_schema_klass.id }
          schema_association&.id
        end

        def message_associations_to_import(messages_by_record, rule, schema_association_id)
          return [] unless schema_association_id

          result = []
          rule_target_klass = rule.klass

          messages_by_record.each do |record_id, messages|
            contact_emails = begin
              contact = rule_target_klass.find(record_id)
              if contact.respond_to?(:emails)
                contact.emails.to_a.map { |email_record| extract_email_value_from_record(email_record) }.compact.map(&:downcase).uniq
              else
                []
              end
            rescue StandardError
              []
            end

            messages.each do |message|
              message_recipients = self.extract_message_recipients(message)
              should_attach = contact_emails.empty? || (message_recipients & contact_emails).any?
              next unless should_attach

              result << {
                association_owner_type: rule.klass_name,
                association_owner_id: record_id,
                association_target_type: @message_schema_klass.const_absolute_name,
                association_target_id: message['id'],
                schema_association_type: 'Dynamic::Schema::Association::Base',
                schema_association_id: schema_association_id,
              }
            end
          end

          result
        end

        def extract_message_recipients(message)
          recipients = []

          # Extract from 'sender'
          if message['sender'].is_a?(Hash)
            recipients << (message['sender']['address'] || message['sender']['email'] || message['sender']['email_address'])
          end

          # Extract from 'recipients' array
          if message['recipients'].is_a?(Array)
            recipients.concat(message['recipients'].map { |r| r['address'] || r['email'] || r['email_address'] }.compact)
          elsif message['recipients'].is_a?(Hash)
            recipients << (message['recipients']['address'] || message['recipients']['email'] || message['recipients']['email_address'])
          end

          # Extract from 'cc' array
          if message['cc'].is_a?(Array)
            recipients.concat(message['cc'].map { |r| r['address'] || r['email'] || r['email_address'] }.compact)
          end

          # Extract from 'bcc' array
          if message['bcc'].is_a?(Array)
            recipients.concat(message['bcc'].map { |r| r['address'] || r['email'] || r['email_address'] }.compact)
          end

          recipients.compact.map(&:downcase).uniq
        end

        def extract_email_value_from_record(email_record)
          return nil unless email_record

          value =
            if email_record.respond_to?(:address)
              email_record.address
            elsif email_record.respond_to?(:email)
              email_record.email
            elsif email_record.respond_to?(:attributes)
              attributes = email_record.attributes
              attributes['address'] || attributes['email']
            end

          normalized = value.to_s.strip.downcase
          normalized.present? ? normalized : nil
        end

        def reset_parent_message_associations_for_rules!(assoc_klass, rules)
          rule_contexts = Set.new
          rules.each do |rule|
            schema_association_id = schema_association_id_for_rule(rule)
            next unless schema_association_id
            rule_contexts << [rule.klass_name, schema_association_id]
          end.compact.uniq

          return if rule_contexts.empty?

          rule_contexts.each do |owner_type, schema_association_id|
            assoc_klass.where(
              association_owner_type: owner_type,
              association_target_type: @message_schema_klass.const_absolute_name,
              schema_association_type: 'Dynamic::Schema::Association::Base',
              schema_association_id: schema_association_id,
              deleted_at: nil
            ).each(&:destroy)
          end
        end

        def import_parent_message_associations!(assoc_klass, rows)
          rows = reject_existing_association_rows(assoc_klass, rows)
          return if rows.empty?

          assoc_klass.import(
            rows,
            on_duplicate_key_ignore: {
              conflict_target: [
                :association_owner_type,
                :association_owner_id,
                :association_target_type,
                :association_target_id,
                :schema_association_id,
                :schema_association_type,
                :deleted_at
              ]
            }
          )
        end

        def reject_existing_association_rows(assoc_klass, rows)
          rows = rows.uniq do |row|
            [
              row[:association_owner_type],
              row[:association_owner_id],
              row[:association_target_type],
              row[:association_target_id],
              row[:schema_association_type],
              row[:schema_association_id]
            ]
          end

          return [] if rows.empty?

          remaining = []

          rows.group_by do |row|
            [
              row[:association_owner_type],
              row[:association_target_type],
              row[:schema_association_type],
              row[:schema_association_id]
            ]
          end.each do |group_key, group_rows|
            owner_type, target_type, schema_association_type, schema_association_id = group_key
            owner_ids = group_rows.map { |row| row[:association_owner_id] }.uniq
            target_ids = group_rows.map { |row| row[:association_target_id] }.uniq

            existing_pairs = assoc_klass.where(
              association_owner_type: owner_type,
              association_target_type: target_type,
              schema_association_type: schema_association_type,
              schema_association_id: schema_association_id,
              deleted_at: nil,
              association_owner_id: owner_ids,
              association_target_id: target_ids
            ).pluck(:association_owner_id, :association_target_id).each_with_object({}) do |(owner_id, target_id), hash|
              hash[[owner_id, target_id]] = true
            end

            group_rows.each do |row|
              key = [row[:association_owner_id], row[:association_target_id]]
              remaining << row unless existing_pairs[key]
            end
          end

          remaining
        end

        def already_running_for?(schema_id)
          ::Sidekiq.redis do |redis|
            redis.get(redis_lock_key(schema_id)) == 'running'
          end
        end

        def register_running_for(schema_id)
          ::Sidekiq.redis do |redis|
            redis.set(redis_lock_key(schema_id), 'running', ex: 7200)
          end
        end

        def deregister_running_for(schema_id)
          ::Sidekiq.redis do |redis|
            redis.del(redis_lock_key(schema_id))
          end
        end

        def redis_lock_key(schema_id)
          "mail_hosting_sync_attachment_job:#{schema_id}"
        end
      end
    end
  end
end