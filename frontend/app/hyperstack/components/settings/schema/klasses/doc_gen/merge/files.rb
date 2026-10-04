class Settings

  class Schema

    module DocGen

      module Merge

        class Files < Base

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
            schema.const::R::DocGen::Merge::File
          end

          def new_record
            return nil unless klass
            klass.polymorphic_new(type: 'StaticFile', klass_id: schema_klass_id, template: template)
          end

          def scope_for_all
            {
              klass_id: schema_klass_id,
              template_id: template_id,
            }
          end

          def self.includes_for_all
            {
              include: {
                template: 1,
                file: Dynamic::Base.active_storage_includes,
                object_template: {
                  translations: 1,
                },
              },
            }
          end

          def parent_page(params = {})
            ::Stackable::Page() do
              ::Stackable::Toolbar() do
                ::Stackable::PageHeader(title: template&.name, back: templates_location)
              end
              ::Stackable::List({
                active: params[:active],
                items: ::Settings::Schema::DocGen::Templates.children_items(schema, template.class),
                location: back_location
              })
            end
          end

          def parent_parent_page(params = {})
            CollectionPage(
              klass: schema.const::R::DocGen::Template,
              resource_id_key: :template_id,
              path_prefix: path_prefix,
              location: templates_location,
              location_suffix: '',
              scope_for_all: { klass_id: match.params[:klass_id] },
            )
          end

          def back_location
            "#{templates_location}/#{match.params[:template_id]}"
          end

          class EditPanel < ::Settings::Schema::EditPanel

            before_receive_props do
              @current_klass = nil
            end

            render { content }

            def form
              @current_klass ||= "#{schema.const}::R::DocGen::Merge::#{record.type}".safe_constantize if record&.type
              Form(record: record) do
                Form::Element::Attribute::Enum(
                  attribute_name: 'type',
                  disabled: record.persisted?,
                ) do
                  files_klasses.map do |klass|
                    OPTION(value: klass.name[(schema.const::R::DocGen::Merge.name.length+2)..-1]) do
                      klass.try(:model_name).try(:human) || klass.name
                    end
                  end
                end.on(:change) do |value, form, element|
                  @current_klass = "#{schema.const}::R::DocGen::Merge::#{value}".safe_constantize
                  form.submission.clean_klass_params!(@current_klass, element.prefix_path)
                  mutate
                end
                Form::Element::Layout::Condition(type: { like: /(?:\A|::)StaticFile\z/ }) do
                  Form::Element::Attachment::HasOne(
                    klass: @current_klass,
                    attribute_name: 'file',
                  )
                end
                Form::Element::Layout::Condition(type: { like: /(?:\A|::)AttributeFile\z/ }) do
                  if record.template # sometime record has wrong class due to polymorphism and async, so no template
                    Form::Element::Attribute::Array(
                      attribute_name: 'attribute_path',
                      klass: @current_klass,
                      label: I18n.t('activerecord.attributes.dynamic/doc_gen/template.attribute_path'),
                      possible_values: possible_attributes,
                      selectable_expandable_option: false,
                      record_klass: record.template.klass,
                    )
                  end
                end
                Form::Element::Layout::Condition(type: { like: /(?:\A|::)TemplateFile\z/ }) do
                  Form::Element::Association::BelongsTo(
                    klass: @current_klass,
                    attribute_name: 'object_template_id',
                    # TODO filter on class_name (+ multiple ?)
                  )
                end
              end.on(:success) do
                App.history.push(record_location)
              end
            end

            def footer
              form_footer
            end

            private

            def possible_attributes
              Proc.new do |klass, prefix|
                result = []
                result = klass&.reflect_on_all_attachments&.map do |a|
                  { value: "#{prefix}#{a.name}", label: record.template&.klass&.human_attribute_name(a.name), tree_level: prefix.split('.').size }
                end
                klass&.reflect_on_all_associations&.each do |reflection|
                  next unless reflection.klass
                  result << {
                    label: klass.human_attribute_name(reflection.name),
                    value: "#{prefix}#{reflection.name}.",
                    klass: reflection.klass,
                    tree_level: prefix.split('.').size,
                  }
                end
                result
              end
            end

            def files_klasses
              [
                schema.const::R::DocGen::Merge::StaticFile,
                schema.const::R::DocGen::Merge::AttributeFile,
                schema.const::R::DocGen::Merge::TemplateFile,
              ]
            end

          end

        end

      end

    end

  end

end
