require 'components/form/element/attribute/base'

class Form
  module Element
    module Attribute

      class Translatable < ::Form::Element::Attribute::Base

        FLAGS = {
          'fr' => '🇫🇷',
          'en' => '🇬🇧',
          'es' => '🇪🇸',
        }

        render { content }

        private

        def init_submission_params(record = self.record, prefix_path = self.prefix_path)
          return unless form && record
          old = @locale

          I18n.available_locales.each do |locale|
            @locale = locale

            path = prefix_path + [localized_attribute_name]
            next if form.submission.has_key?(path)

            unless form.submission.read(path)
              value = record.send(localized_attribute_name)
              value = other_params[:default_value].try(:[], locale) if value.nil? || forced_default_value?
              form.submission.write_from_db(path, value)
            end

            if nullify? && form.submission.read(path) == ''
              form.submission.write_from_db(path, nil)
            end
          end
          @locale = old

          init_position
        end

        def input_name
          "#{input_prefix}[#{localized_attribute_name}]"
        end

        def localized_attribute_name
          "#{attribute_name}_#{@locale || I18n.locale}"
        end

        def localized_form_group_id
          "#{input_name&.gsub(/\[|\./, '-')&.gsub(']', '')}-#{@locale || I18n.locale}"
        end

        def input_id
          "input-#{localized_form_group_id}"
        end

        def attributes_for_errors
          [localized_attribute_name] + Array(errors_from)
        end

        def attribute_names
          I18n.available_locales.map{|locale| "#{attribute_name}_#{locale}"}
        end

        def change_value(value, locale = I18n.locale)
          return unless form
          old = @locale
          @locale = locale
          old_value = form.submission.read(path)
          new_value = convert_value(value)
          if new_value != old_value
            form.enable
            form.submission.write_from_user(path, new_value)
            change_data(value)
            @locale = old
            mutate
            change!(value, form, self, locale)
            form.change
          end
          @locale = old
        end

        def path
          prefix_path + [localized_attribute_name]
        end

        def localized_placeholder
          other_params[:"placeholder_#{@locale}"] || placeholder
        end

        def for_each_locale
          ([I18n.locale] + I18n.available_locales).uniq.each_with_index do |locale, i|
            @locale = locale
            yield(locale, i)
          end
        end

        def compact?
          other_params[:compact] != false
        end

        def layout_globalize_inputs
          DIV(ref: _ref, class: 'row') do
            DIV(class: 'col') do
              yield
            end
          end
        end
      end
    end
  end
end
