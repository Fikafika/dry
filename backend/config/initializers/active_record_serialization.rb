module ActiveRecord
  module Serialization
    extend ActiveSupport::Concern

    def serializable_hash(options = nil)
      options = options.try(:clone) || {}

      options[:except] = Array(options[:except]).map(&:to_s)

      super(options)
    end

  end
end
