# backtick_javascript: true

require 'components/form/element/base'

class Crm
  class ExportAllModal < ::Modal

    param :klass

    render { content }

    EXPORT_TYPE_BY_LOCALIZATION_KEY = {
      'csv_cp1252' => 'csv::cp1252',
      'csv_utf_8' => 'csv::utf-8',
      'xml_utf_8' => 'xml::utf-8',
      'xml_cp1252' => 'xml::cp1252',
    }.freeze

    DATE_FORMAT_BY_LOCALIZATION_KEY = {
      'DD-MM-YYYY H:M:S' => '%d-%m-%Y %H:%M:%S',
      'YYYY-MM-DD' => '%Y-%m-%d',
      'YY-MM-DD' => '%y-%m-%d',
      'DD-MM-YY' => '%d-%m-%y',
      'DD-MM-YYYY' => '%d-%m-%Y',
      'DD/MM/YY' => '%d/%m/%y',
      'DD/MM/YYYY' => '%d/%m/%Y',
    }.freeze

    SEPARATOR_BY_LOCALIZATION_KEY = {
      'semi_colon' => ';',
      'comma' => ',',
    }.freeze

    DECIMAL_SEPARATOR_BY_LOCALIZATION_KEY = {
      'comma' => ',',
      'dot' => '.',
    }.freeze

    def title
      Dynamic::Export::Setting.model_name.human
    end

    def body
      form_elements
    end

    def confirm
      form = Form.current
      confirm!(form.submission.params.values.first)
      close
    end

    def form_elements
      Form(record: ::HyperResource::Base.new) do
        LinkedAttributes(possible_values: possible_export_types, attribute_name: 'export_type::encoding_type', label: I18n.t('crm.export.settings.export_types.title'), default_value: 'csv::cp1252')

        Form::Element::Layout::Condition(export_type: ['csv']) do
          ::Form::Element::Attribute::Enum(
            attribute_name: 'separator',
            label: I18n.t('crm.export.settings.separators.title'),
            possible_values: possible_separators,
            accept_empty_value: false,
            default_value: ';'
          )
        end
        LinkedAttributes(possible_values: possible_decimal_separators, attribute_name: 'decimal_separator', label: I18n.t('crm.export.settings.decimal_separators.title'), default_value: ',')
        LinkedAttributes(possible_values: possible_locales, attribute_name: 'locale', label: I18n.t('crm.export.settings.language.title'), default_value: default_language)
        LinkedAttributes(possible_values: possible_date_format, attribute_name: 'date_format', label: I18n.t('crm.export.settings.date_formats.title'), default_value: '%d-%m-%Y %H:%M:%S')
        ::Form::Element::Attribute::Boolean(
          attribute_name: 'apply_attribute_format',
          label: I18n.t('crm.export.settings.apply_attribute_format'),
          default_value: true,
        )
      end
    end

    def default_language
      browser_language = `navigator.language || navigator.userLanguage`
      browser_language.split('-')[0] || User.current&.language || :en
    end

    def possible_export_types
      @possible_export_types ||= EXPORT_TYPE_BY_LOCALIZATION_KEY.map do |key, value|
        {
          label: I18n.t("crm.export.settings.export_types.#{key}"),
          value: value,
        }
      end
    end

    def possible_separators
      @possible_separators ||= SEPARATOR_BY_LOCALIZATION_KEY.map do |key, value|
        {
          label: I18n.t("crm.export.settings.separators.#{key}"),
          value: value,
        }
      end
    end

    def possible_decimal_separators
      @possible_decimal_separators ||= DECIMAL_SEPARATOR_BY_LOCALIZATION_KEY.map do |key, value|
        {
          label: I18n.t("crm.export.settings.separators.#{key}"),
          value: value,
        }
      end
    end

    def possible_locales
      @possible_locales ||= I18n.available_locales.map do |locale|
        {
          label: I18n.t("lang.#{locale}"),
          value: locale,
        }
      end
    end

    def possible_date_format
      @possible_date_format ||= DATE_FORMAT_BY_LOCALIZATION_KEY.map do |format_key, format_value|
        {
          label: I18n.t("crm.export.settings.date_formats.#{format_key}"),
          value: format_value,
        }
      end
    end

    class LinkedAttributes < Form::Element::Base

      render { content }

      def content
        DIV(class: 'row form-group') do
          LABEL(class: 'col-md-3 control-label') do
            label
          end
          DIV(class: 'col-md-9') do
            SELECT(class: 'form-control') do
              possible_values.each do |p_value|
                OPTION(value: p_value[:value]) do
                  p_value[:label]
                end
              end
            end.on(:change) do |event|
              change_value(event.target.value)
            end
          end
        end
      end

      def init_submission_params
        return if path.any? {|path_| Form.current.submission.read(path_)}
        change_value(default_value)
      end

      def change_value(value)
        return if form&.reseting?
        values = value.split('::')
        values.each_with_index do |val, i|
          old_value = form.submission.read(path[i])
          new_value = convert_value(val)
          if new_value != old_value
            form.enable
            form.submission.write_from_user(path[i], new_value)
            change_data(val)
            change!(val, form, self)
            form.change
          end
        end
        form&.mutate
      end

      def default_value
        other_params[:default_value]
      end

      def label
        other_params[:label]
      end

      def possible_values
        other_params[:possible_values]
      end

      def path
        return [] unless prefix_path
        @submission_paths ||= attribute_name.split('::').map do |name|
          prefix_path + [name]
        end
      end

    end
  end
end
