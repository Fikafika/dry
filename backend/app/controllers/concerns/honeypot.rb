# frozen_string_literal: true

module Honeypot; extend ActiveSupport::Concern

private

  def protect_from_spam
    return if honeypot_fields.all?{|f, l| params[f].blank?}
    head :ok # we could return :unprocessable_content but with :ok, the bot will believe that the form was successfully submitted
  end

  def honeypot_fields
    [
      :a_comment_body,
    ].freeze
  end

  def honeypot_string
    'hp'
  end

end
