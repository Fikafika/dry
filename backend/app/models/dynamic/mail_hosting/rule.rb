module Dynamic
  module MailHosting
    class Rule < ActiveRecord::Base

      self.abstract_class = true

      include Dynamic::Mount

      define_table do |t|
        t.string :name
        t.string :klass_name
        t.string :record_id, null: true
        t.string :user_sso_id
        t.datetime :last_sync, null: true
      end


      after_mount do
        has_many :conditions, class_name: "Condition", inverse_of: :rule
        accepts_nested_attributes_for :conditions, allow_destroy: true
        validates :klass_name, :inclusion=> { :in => self.module_parent.module_parent.module_parent.klasses_associated_to_message }
        after_commit :enqueue_parent_attachment_recompute_async
      end

      def klass
        klass_name.safe_constantize
      end

      def record
        klass.find(record_id)
      end

      def records_in_batches
        if record_id
          yield [record]
        else
          klass.find_in_batches(batch_size: 50) do |batch|
            yield batch
          end
        end
      end

      def messages_for(records, schema)
        community = Community.find_by(schema: schema)
        unless community
          raise StandardError, "MailHosting community not found for schema_id=#{schema&.id} schema_name=#{schema&.name}"
        end

        connexion = Faraday.new(
          url: "#{ENV['UNEEK_MAIL_APP_PROTOCOL']}://#{ENV['UNEEK_MAIL_APP_HOST']}/",
          params: { community_id: community.uneek_sso_uuid },
          headers: {'Content-Type' => 'application/json'}
        ) do |conn|
          conn.request :authorization, :basic, ENV["UNEEK_MAIL_APP_USERNAME"], ENV["UNEEK_MAIL_APP_PASSWORD"]
          conn.response :json, content_type: /\bjson/
        end

        request_body = build_request_body(records)

        response = connexion.post("api/email/messages/filter", { rules: request_body }.to_json)

        unless response.success?
          raise StandardError, "MailHosting authentication failed: status=#{response.status} body=#{response.body}"
        end

        unless response.body.is_a?(Hash)
          raise StandardError, "MailHosting invalid response: status=#{response.status} body=#{response.body}"
        end

        response.body
      end

      protected

      def build_request_body(records)
        result = {}
        records.each do |record|
          result[record.id] = rule_for_record(record)
        end
        result
      end

      def rule_for_record(record)
        result = {}
        conditions.each do |condition|
          value = value_for_record(condition.value, record)
          values = Array(value).compact.reject { |entry| entry.respond_to?(:blank?) ? entry.blank? : false }
          next if values.empty?

          result[condition.attr] ||= {}
          result[condition.attr][condition.json_operator] ||= []
          result[condition.attr][condition.json_operator] += values
        end
        result
      end

      def value_for_record(formula, record)
        return nil if formula.blank?

        Dynamic::Formula.new(formula).eval(record: record)
      rescue Uneek::Formula::Error => error
        Rails.logger.warn(
          "MailHosting skipped invalid rule formula rule_id=#{id} record_id=#{record&.id} formula=#{formula.inspect} error=#{error.class}: #{error.message}"
        )
        nil
      end

      def enqueue_parent_attachment_recompute_async
        self.class.enqueue_parent_attachment_recompute_for_rules_class(self.class)
      end

      def self.enqueue_parent_attachment_recompute_for_rules_class(rules_class)
        schema_module_name = rules_class&.name.to_s.split('::')[1]
        return if schema_module_name.blank?

        schema = Dynamic::Schema.find_by(name: schema_module_name.underscore)
        return unless schema

        Dynamic::MailHosting::Worker::Attachment.perform_async(schema.id)
      end

    end
  end
end