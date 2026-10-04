require 'uneek_formatting'

I18n.available_locales = [:en, :fr]
I18n.default_locale = :fr
Globalize.fallbacks = {:en => [:en, :fr], :fr => [:fr, :en]}
UneekFormatting.configure_i18n

# fix crash when select distinct
module GlobalizeFix
  def with_translations_in_fallbacks
    with_translations([I18n.locale])
  end
end
Globalize::ActiveRecord::TranslatedAttributesQuery.prepend(GlobalizeFix)
require 'phonelib'
Phonelib.default_country = ['FR', 'GP', 'PM', 'MQ', 'RE', 'GF']
Phonelib.parse_special = true
Phonelib.extension_separate_symbols = 'x'
