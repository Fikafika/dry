class Settings

  class Schema

    module DocGen

      class Templates < Base

        render { content }

        def content
          observe schema
          if schema.constants_loaded? && schema.has_feature_enabled?('Dynamic::DocGen::Feature')
            super
          else
            DIV() do
            end
          end
        end

        def klass
          schema.const::R::DocGen::Template
        end

        def new_record
          klass&.polymorphic_new(
            type: 'DocxTemplate',
            klass_id: schema_klass_id,
            class_name: "#{schema.const.name}::#{schema_klass_id.camelize}",
            multiple: false
          )
        end

        def scope_for_all
          {
            klass_id: schema_klass_id,
          }
        end

        def self.includes_for_show
          {
            include: {
              translations: 1,
              docx: Dynamic::Base.active_storage_includes,
              wrapped_template: 1,
            },
          }
        end

        class EditPanel < ::Settings::Schema::EditPanel

          before_receive_props do
            @current_klass = nil
          end

          render { content }

          def form
            @current_klass ||= "#{schema.const}::R::DocGen::#{record.type}".safe_constantize if record&.type
            Form(record: record) do
              Form::Element::Attribute::TranslatableString(
                attribute_name: 'name',
                auto_focus: true,
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'type',
                disabled: record.persisted?,
              ) do
                template_klasses.map do |klass|
                  OPTION(value: klass.name[(schema.const::R::DocGen.name.length+2)..-1]) do
                    klass.try(:model_name).try(:human) || klass.name
                  end
                end
              end.on(:change) do |value, form, element|
                @current_klass = "#{schema.const}::R::DocGen::#{value}".safe_constantize
                form.submission.clean_klass_params!(@current_klass, element.prefix_path)
                mutate
              end
              Form::Element::Layout::Condition(type: { like: /(?:\A|::)DocxTemplate\z/ }) do
                Form::Element::Attachment::HasOne(
                  klass: @current_klass,
                  attribute_name: 'docx',
                )
              end
              Form::Element::Layout::Condition(type: { like: /(?:\A|::)WrapperTemplate\z/ }) do
                Form::Element::Association::BelongsTo(
                  klass: @current_klass,
                  attribute_name: 'wrapped_template_id',
                  # TODO filter on class_name (+ multiple ?)
                )
                Form::Element::Attribute::Enum(
                  attribute_name: 'wrapped_format',
                  possible_values: record.possible_formats.map{|f| { value: f, label: f.upcase }}, # TODO remove empty value
                )
              end
              Form::Element::Attribute::Boolean(
                attribute_name: 'multiple',
              )
              Form::Element::Attribute::String(
                attribute_name: 'output_name_formula',
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'default_attachment',
                possible_values: record.klass&.reflect_on_all_attachments&.map{|a| { label: record.klass.human_attribute_name(a.name), value: a.name }} || [],
              )
              Form::Element::Attribute::Enum(
                attribute_name: 'output_locale',
                possible_values: I18n.available_locales.map{|l| { value: l.to_s, label: l.to_s.upcase }},
                default_value: I18n.locale.to_s,
                accept_empty_value: false,
              )
            end.on(:success) do
              App.history.push(record_location)
            end
            children_list
          end

          def children_items
            return self.class.parent.children_items(schema, @current_klass)
          end

          def footer
            form_footer
          end

          private

          def template_klasses
            [
              schema.const::R::DocGen::DocxTemplate,
              schema.const::R::DocGen::WrapperTemplate,
              schema.const::R::DocGen::Merge::PdfTemplate,
              schema.const::R::DocGen::Merge::ZipTemplate,
            ]
          end

        end

      end

    end

  end

end
