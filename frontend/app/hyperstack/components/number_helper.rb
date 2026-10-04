# backtick_javascript: true

module NumberHelper
  extend self

  def number_to_phone(number, options = {})
    return unless number
    raise 'not implemented' # TODO use PhoneLib
  end

  def number_to_rounded(number, options = {})
    return unless number
    raise 'not implemented' # TODO use ActiveSupport::NumberHelper
  end

  if RUBY_ENGINE == 'opal'

    def number_to_percentage(number, options = {})
      return unless number
      "#{`#{number}.toLocaleString()`} %"
    end

    def number_to_currency(number, options = {})
      return unless number
      return number unless options[:currency]
      return `new Intl.NumberFormat(#{I18n.locale}, { style: "currency", currency: #{options[:currency]} }).format(#{number})`
    end

  else

    def number_to_percentage(number, options = {})
      return unless number
      raise 'not implemented' # TODO use ActiveSupport::NumberHelper
    end

    def number_to_currency(number, options = {})
      return unless number
      raise 'not implemented' # TODO use ActiveSupport::NumberHelper
    end

  end
end
