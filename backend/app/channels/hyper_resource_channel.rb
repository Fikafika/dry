# frozen_string_literal: true

class HyperResourceChannel < ApplicationCable::Channel

  class << self
    def broadcast(record)
      return unless record.respond_to?(:broadcast_user_id)
      channel = channel_name_for_broadcast(record.class, record.broadcast_user_id)
      return unless channel
      ActionCable.server.broadcast(channel, record.as_json)
    end

    def channel_name_for_broadcast(klass, user_id)
      klass_part = klass.table_name

      if user_id
        # broadcast only to user_id
        user_part = user_id
      else
        # broadcast to all users
        user_part = nil
      end

      return build_channel_name(klass_part, user_part)
    end

    def build_channel_name(klass_part, user_part)
      ['hyper_resource', klass_part, user_part ].join('|')
    end
  end

  def subscribed
    # TODO check params[:user_id] == User.current.id ? how to authenticate ?
    channel = channel_name_for_subscription(params[:type], params[:user_id])
    return unless channel
    stream_from channel
  end

  def channel_name_for_subscription(klass_name, user_id)
    return unless klass_name

    if klass_name == 'HyperResource::Base'
      return unless user_id
      # for after completed jobs callbacks
      # see app/controllers/concerns/enable_wait_for_completed_jobs.rb
      klass_part = 'completed_jobs'
    else
      load_schema(klass_name)
      k = klass_name.safe_constantize
      return unless k
      klass_part = k.table_name
    end

    if user_id
      # subscribe to records that broadcasts to user_id
      user_part = user_id
    else
      # subscribe to records that broadcasts to all users
      user_part = nil
    end

    return self.class.build_channel_name(klass_part, user_part)
  end

  def load_schema(klass_name)
    return unless klass_name.start_with?('D::')
    schema_name = klass_name.split('::')[1]
    Dynamic::Schema.load(schema_name) unless Dynamic::Schema.loaded_schemas[schema_name]
  end

end
