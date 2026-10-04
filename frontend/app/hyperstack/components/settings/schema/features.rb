class Settings

  class Schema

    class Features < ::Settings::Schema::Base

      render{ content }


      def klass
        ::Dynamic::Schema::Feature
      end

      def scope_for_all
        super.merge(visible: true)
      end

      def editable?
        false
      end

      def self.includes_for_all
        { include: { translations: 1, options: 1, default_options_for_concern: 1, concerns: 1} }
      end

      def self.child_klasses
        {
          ::Dynamic::Schema::Concern => true,
        }
      end

      def self.children_items(schema)
        child_klasses.map do |a, plural|
          {
            id: resources_name(a),
            icon: a.icon,
            title: a.model_name.human(count: (plural ? 2 : 1)),
          }
        end.compact
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        class << self
          def options(schema, feature)
            if schema.loaded?
              Form::Element::Association::HasMany(mode: 'nested_form', attribute_name: 'options', show_item_header: false, show_label: false, show_item_separator: false) do
                Form::Element::Attribute::String(attribute_name: 'id', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'type', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'human_name', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'human_name_fr', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'human_name_en', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'name', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'coder_type', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'global', editor: 'hidden')
                OptionValue(attribute_name: 'value', schema: schema, feature: feature)
              end
            end
          end
        end

        def form
          Form(record: record) do
            Form::Element::Attribute::Boolean(
              attribute_name: 'enabled',
              disabled: record.mandatory,
              errors_from: :concerns,
            )
            comment
            self.class.options(schema, record)
            children_list
          end.on(:success) do
            others[:schema].stale!
            App.history.push(record_location)
          end

        end

        def footer
          form_footer
        end

        class OptionValue < ::Form::Element::Attribute::Base

          param :schema, default: nil
          param :feature, default: nil

          track_changes :feature

          after_new_params do
            @nested_form = nil if feature_changed?
          end

          render do
            layout_input do
              e = self.class.element_klass_data(schema, klass, type, coder_type, option_name)
              e[:type].constantize.create_element({
                form: nested_form,
                prefix_path: ['option'],
                attribute_name: 'value',
              }.merge(e[:params])).on(:change) do |value, form, el|
                v = el.convert_value(value)
                change_value(v)
              end
            end
          end

          class << self

            def element_klass_data(schema, klass, type, coder_type, option_name = nil)
              case [type, coder_type]
              when ['String', 'Dynamic::Schema::Option::Coder::Klass']
                {
                  type: 'Form::Element::Attribute::Enum',
                  params: {
                    possible_values: klass_possible_values(schema),
                  }
                }
              when ['String', 'Dynamic::Schema::Option::Coder::Klasses']
                {
                  type: 'Form::Element::Attribute::MultipleEnum',
                  params: {
                    editor: 'select2',
                    possible_values: klass_possible_values(schema),
                  }
                }
              when ['String', 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach']
                {
                  type: 'Form::Element::Attribute::Enum',
                  params: {
                    possible_values: attr_or_assoc_or_attach_possible_values(schema, klass),
                  }
                }
              when ['String', 'Dynamic::Schema::Option::Coder::Path']
                {
                  type: 'Form::Element::Attribute::Array',
                  params: {
                    possible_values: path_possible_values(schema, klass),
                    possible_values_timestamp: klass&.id, # for update results when klass changes
                  }
                }
              when ['Hash', 'Dynamic::Schema::Option::Coder::MappingOfAttrOrAssocOrAttach']
                {
                  type: 'Form::Element::Attribute::Hash',
                  params: {
                    editor: 'enum',
                    possible_values: option_name == 'output_mapping' ? attr_or_assoc_or_attach_possible_values(schema, nil) : attr_or_assoc_or_attach_possible_values(schema, klass),
                  }
                }
              else
                {
                  type: "Form::Element::Attribute::#{type}",
                  params: {
                    possible_values: [],
                  }
                }
              end
            end

            def klass_possible_values(schema)
              @klass_possible_values ||= schema.klasses.sort_by{|k| k.human_name.capitalize }.map do |k|
                {value: k.id, label: k.human_name.capitalize}
              end
            end

            def path_possible_values(schema, klass = nil)
              context_klass = klass
              Proc.new do |klass, prefix|
                result = []
                if klass.nil? && context_klass.nil?
                  result << {}
                  schema.klasses.sort_by{|k| k.human_name.capitalize }.each do |k|
                    result << {
                      label: k.human_name.capitalize,
                      value: "#{k.id}.",
                      klass: k,
                      tree_level: 0,
                    }
                  end
                else
                  if klass.nil? && context_klass
                    klass = context_klass
                    result << {}
                  end
                  if klass
                    (klass.attrs + klass.associations + klass.attachments).sort_by{|a| a.human_name.capitalize }.each do |a|
                      o = {
                        value: "#{prefix}#{a.id}",
                        label: a.human_name.capitalize,
                        tree_level: prefix.to_s.split('.').size,
                      }
                      if a.is_a?(Dynamic::Schema::Association::Base)
                        o[:klass] = a.target_klass
                        o[:value] = "#{o[:value]}." if a.target_klass
                      end
                      result << o
                    end
                  end
                end
                result
              end
            end

            def attr_or_assoc_or_attach_possible_values(schema, klass = nil)
              @attr_or_assoc_or_attach_possible_values ||= {}
              return @attr_or_assoc_or_attach_possible_values[klass] if @attr_or_assoc_or_attach_possible_values[klass]

              result = []
              if klass
                (klass.attrs + klass.associations + klass.attachments).sort_by{|a| a.human_name.capitalize }.each do |a|
                  result << {value: a.id, label: a.human_name.capitalize }
                end
              else
                schema.klasses.sort_by{|k| k.human_name.capitalize }.each do |k|
                  (k.attrs + k.associations + k.attachments).sort_by{|a| a.human_name.capitalize }.each do |a|
                    result << {value: a.id, label: "#{k.human_name.capitalize} > #{a.human_name.capitalize}" }
                  end
                end
              end

              @attr_or_assoc_or_attach_possible_values[klass] = result
              return result
            end

          end

          def type
            form.submission.read(prefix_path + ['type'])
          end

          def coder_type
            form.submission.read(prefix_path + ['coder_type'])
          end

          def option_name
            form.submission.read(prefix_path + ['name'])
          end

          def klass
            return nil if global
            if klass_id
              return schema.klasses_by_id[klass_id]
            end
            return @klass if @klass
            @klass = nil
            if record.owner_type == 'Dynamic::Schema::Concern'
              # owner should be preloaded
              owner = nil
              schema.features.each do |f|
                owner = f.concerns.detect{|c| c.id == record.owner_id }
                break if owner
              end
              @klass = schema.klasses_by_id[owner.klass_id] if owner
            end
            return @klass
          end

          def global
            form.submission.read(prefix_path + ['global'])
          end

          def klass_id
            form.submission.read(['concern', 'klass_id'])
          end

          def nested_form
            @nested_form ||= ::Form::FakeForm.new
            unless @nested_form.submission.has_key?(['option', 'value'])
              value = form.submission.read(prefix_path + ['value'])
              @nested_form.submission.write(['option', 'value'], value)
            end
            return @nested_form
          end

          def displayed_label
            form.submission.read(prefix_path + ['human_name'])
          end

        end

      end

    end

  end

end
