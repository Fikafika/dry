# backtick_javascript: true

if RUBY_ENGINE == 'opal'

  module I18n
    class << self
      def t(key, options = {})
        if options&.any?
          options[:defaultValue] = options.delete(:default)
        end
        return `I18n.t(#{key}, #{options.to_n})`
      end

      def locale
        return `I18n.locale`
      end

      def locale=(l)
        `I18n.locale=#{l}`
      end

      def default_locale
        `I18n.defaultLocale`
      end

      def available_locales
        return `Object.keys(I18n.translations)`
      end

      def error(e, record, attr)
        result = nil
        klass = record.is_a?(Class) ? record : record.class
        while (result.nil? || result.start_with?('[missing')) && klass != Object do
          result = I18n.t("activerecord.errors.models.#{klass.name.underscore}.attributes.#{attr}.#{e['error']}", e)
          klass = klass.superclass
        end
        if result.start_with?('[missing')
          translated_e = {}
          e.each do |k, v|
            if k == 'attrs' # TODO should try to translate each element when v is an array
              translated_e[k] = v.map {|attr| record.class.human_attribute_name(attr)}.join(', ')
            elsif v.is_a?(::String)
              translated_e[k] = I18n.l(v)
            else
              translated_e[k] = v
            end
          end
          result = I18n.t("errors.messages." + e['error'], translated_e)
        end
        return result
      end

      def with_locale(l)
        old = I18n.locale
        begin
          I18n.locale = l
          result = yield
          I18n.locale = old
        ensure
          I18n.locale = old
        end
        return result
      end

      def l(o, options = {})
        case o
        when String
          result = o
          if options[:format]
            result = `moment(#{o}).format(#{I18n.t("format.#{options[:format]}")})`
          else
            result = `moment(#{o}).format(#{I18n.t('format.date')})` if !!(o&.match "[0-9]{4}-[0-9]{2}-[0-9]{2}")
            result = `moment(#{o}).format(#{I18n.t('format.date_time')})` if !!(o&.match "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}Z")
          end
        else
          # TODO
        end
        return result
      end

      def errors_message(record, errors)
        lines = []
        errors.each do |k,v|
          attr = record&.class&.human_attribute_name(k)&.downcase || k
          v.each do |m|
            lines << [attr, I18n.error(m, record, k)].join(' ')
          end
        end

        return lines.join('</br>')
      end
    end
  end

  module Globalize
    def self.fallbacks
      {:en => [:en, :fr], :fr => [:fr, :en] }
    end
  end

end
