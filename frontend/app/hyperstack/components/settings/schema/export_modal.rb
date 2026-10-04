class Settings
  class Schema
    class ExportModal < ::Modal

      param :schema_id
      param :filename

      render { content }

      def title
        I18n.t('settings.schema.export')
      end

      def body
        Form(record: record) do
          Form::Element::Attribute::Boolean(attribute_name: 'forms', label: I18n.t('activerecord.models.dynamic/form.other'))
          Form::Element::Attribute::Boolean(attribute_name: 'layouts', label: I18n.t('activerecord.models.dynamic/layout.other'))
        end.on(:change) do |form|
          @export_options = {
            forms: form.submission.params.dig('hyper_resource', 'forms'),
            layouts: form.submission.params.dig('hyper_resource', 'layouts'),
          }
          mutate
        end
      end

      def record
        @record ||= HyperResource::Base.new
      end

      def footer
        BUTTON(class: 'btn bg-light mr-2') do
          cancel_btn_text
        end.on(:click) do |event|
          cancel
        end
        A(href: export_url, download: filename, class: 'btn btn-primary', disabled: !confirm_enabled?) do
          I18n.t('shared.download')
        end
      end

      def export_url
        Dynamic::Schema.member_path(
          id: schema_id,
          pretty_print: true,
          predefined_only: {name: :only_for_export},
          predefined_include: {name: :includes_for_export, args: [export_options]},
        )
      end

      def export_options
        @export_options || {}
      end
    end
  end
end
