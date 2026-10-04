class Layout
  class Editor
    module Panel
      module Forms
        class Base <  Panel::Base
          include Associations

          collect_other_params_as :other_params

          render { content }

          def parameters
            form_id_parameter
          end

          def form_id_parameter
            ::Form::Element::Association::BelongsTo(
              attribute_name: 'dynamic_form_id',
              label: I18n.t('layout_editor.form.label'),
              target_klass: Dynamic::Form,
              target_klass_url: Dynamic::Form.collection_path({schema_id: schema.permalink, klass: klass_name, where: {klass_name: klass_name}, name_attribute: 'human_name'}),
            )
          end

        end
      end
    end
  end
end
