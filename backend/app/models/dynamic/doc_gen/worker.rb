# frozen_string_literal: true

module Dynamic
  module DocGen
    class Worker < ::Dynamic::DocGen::Sidekiq::Worker
      sidekiq_options queue: 'doc_gen', retry: 0

      class << self
        def create_notification(job)
          return unless User.current&.id

          return unless job['args'].length == 3

          notification_attributes = job['args'][2]['notification_attributes']
          return unless notification_attributes

          klass_name = job['args'][0]
          klass = klass_name.safe_constantize
          notification_klass = "#{klass.module_parent.name}::R::Notification".safe_constantize

          attributes = YAML.load(job['args'][1])
          notification_klass&.create(notification_attributes.merge({
            state: :pending,
            user_id: User.current&.id,
            klass_name: 'DocGen::Generation',
            data: {
              template_id: attributes[:template],
              record_type: klass_name,
              record_id: attributes[:records].is_a?(Enumerable) ? nil : attributes[:records],
              attachment: attributes[:attachment],
            },
          }))
        end
      end

      def perform(serialized_klass, serialized_attributes, options = {})
        @progress = options['progress']
        super(serialized_klass, serialized_attributes)
      rescue => e
        if @progress
          @progress.errors << e
          @progress.fail
          nil
        else
          raise
        end
      end

    private

      def perform_unserialized(klass, attributes)
        @generation = perform_generation_klass.new(attributes)

        if @progress
          @progress.before_finish do |final_state|
            next unless final_state == 'success'

            if @generation.output.is_a?(::ActiveStorage::Blob)
              @progress.data['active_storage_attachment'] = active_storage_attachment_data(@generation.output)
            end
          end
        end

        @generation.output

        @generation
      end

      def unserialize_options(klass, serialized_options)
        @webhook_url = serialized_options.delete(:webhook_url)
        if @webhook_url
          if !@progress
            @progress = ::Progress.new
          end

          @progress.after_finish do |final_state|
            body = {
              'generation' => {
                'id' => @generation_id,
                'state' => final_state,
              },
            }
            case final_state
            when 'success'
              if @generation
                if @generation.output.is_a?(::ActiveStorage::Blob)
                  body['generation']['active_storage_attachment'] = active_storage_attachment_data(@generation.output)
                elsif @generation.output.is_a?(Array) && @generation.output.all?{|o| o.is_a?(::ActiveStorage::Blob)}
                  body['generation']['active_storage_attachments'] = @generation.output.map{|o| active_storage_attachment_data(o)}
                end
              end
            when 'fail'
              body['generation']['errors'] = @progress.errors.map{|e| { 'type' => e.class.name, 'message' => e.message, 'backtrace' => e.backtrace }}
            end

            Faraday.new(headers: { 'Content-Type' => 'application/json' }).post(@webhook_url, body.to_json)
          end
        end

        super(klass, serialized_options.merge(progress: @progress))
      end

      def raw_unserialize_attributes(klass, attributes)
        result = super
        @generation_id = result[:id]
        result
      end

      def active_storage_attachment_data(blob)
        {
          'blob_id' => blob.id,
          'signed_id' => blob.signed_id,
          'filename' => blob.filename.to_s,
        }
      end
    end
  end
end
