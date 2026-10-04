ActiveSupport.on_load(:active_record) do

  module Globalize::ActiveRecord::InstanceMethods
    def cache_key # revert globalize cache_key: prevent additional translation query
      "#{cache_key_without_globalize}-#{I18n.locale}"
    end

    def cache_key_without_globalize # from lib/active_record/integration.rb
      if new_record?
        "#{model_name.cache_key}/new"
      else
        if cache_version
          "#{model_name.cache_key}/#{id}"
        else
          timestamp = max_updated_column_timestamp

          if timestamp
            timestamp = timestamp.utc.to_s(cache_timestamp_format)
            "#{model_name.cache_key}/#{id}-#{timestamp}"
          else
            "#{model_name.cache_key}/#{id}"
          end
        end
      end
    end
  end

end
