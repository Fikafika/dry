# frozen_string_literal: true

module Honeypot
  extend self
  extend ActiveSupport::Concern

  def honeypot_fields
    [
      :a_comment_body,
    ].freeze
  end

  def honeypot_string
    'hp'
  end
end
