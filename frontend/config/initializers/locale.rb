I18n.available_locales = [:en, :fr]
I18n.default_locale = :fr
UneekFormatting.configure_i18n
module Globalize
  def self.fallbacks
    {:en => [:en, :fr], :fr => [:fr, :en] }
  end
end
