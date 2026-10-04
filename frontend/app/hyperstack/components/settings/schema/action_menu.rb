# backtick_javascript: true

class Settings
  class Schema
    class ActionMenu < ::HyperComponent

      param :schema, default: nil

      render { content }

      def content
        DIV(class: 'dropdown') do
          BUTTON(class: "btn btn-transparent-light-yiq shadow-none dropdown-toggle dropdown-toggle-ellipsis", type: "button", 'data-toggle': "dropdown") do
          end
          DIV(class: 'dropdown-menu dropdown-menu-right') do
            import_schema
            export_schema
          end
        end
      end

      def import_schema
        import_schema_css_id = 'import_schema'
        INPUT(type: 'file', id: import_schema_css_id, style: {width: 0, height: 0, opacity: 0}, class: 'd-float position-absolute').on(:change) do |event|
          input = event.current_target
          file = `#{input.to_n}.files[0]`
          if file
            read_file(file).then do |f|
              json = JSON.parse(f)
              if json.has_key?('schema_attributes') # community json
                json = json['schema_attributes']
              end
              json.delete('id') # TODO remove ?
              schema.update(json).then do |response|
                if response[:success]
                  import_schema_success
                else
                  import_schema_error(schema.errors)
                end
                input.value = `null`
              end
            end.fail do |e|
              import_schema_error({error: 'fail to read file'})
              input.value = `null`
            end
          else
            import_schema_error({error: 'missing file'})
            input.value = `null`
          end
        end
        A(href: '#import_schema', class: 'dropdown-item text-capitalize-first-letter') do
          I18n.t('settings.schema.import')
        end.on(:click) do |event|
          event.prevent_default
          ::Element.find('#' + import_schema_css_id).click
        end
      end

      def read_file(file)
        result = Promise.new
        `
          var reader = new FileReader();
          reader.readAsText(file, "UTF-8");
          reader.onload = #{Proc.new{|e| result.resolve(`e.target.result`) }}
          reader.onerror = #{Proc.new{|e| result.reject(e) }}
        `
        return result
      end

      def import_schema_error(e)
        schema.const::R::Notification.create(title: I18n.t('shared.error'), body: e.to_s, user_id: User.current.id) # TODO improve error handling
      end

      def import_schema_success
        schema.const::R::Notification.create(title: 'Success', user_id: User.current.id) # TODO
      end

      def export_schema
        ExportModal(id: 'export-schema-modal', schema_id: schema.id, filename: "#{(schema.name || schema.id)&.underscore}.json", portal: true)
        A(href: '#export_schema', 'data-toggle': 'modal', 'data-target': '#export-schema-modal', class: 'dropdown-item text-capitalize-first-letter') do
          I18n.t('settings.schema.export')
        end
      end

    end
  end
end
