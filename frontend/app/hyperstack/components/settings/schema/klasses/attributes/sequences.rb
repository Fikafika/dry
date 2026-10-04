class Settings
  class Schema
    class Attribute
      class Sequences < Attribute::Base

        render { content }

        def klass
          ::Dynamic::Schema::Sequence
        end

        def current_model # TODO fix record loading in order to store klass_id
          m = super
          return unless m
          m.attributes['klass_id'] ||= match.params['klass_id']
          m
        end

        def new_record
          klass.new({
            schema_id: match.params['schema_id'],
            attr_id: match.params['attr_id'],
            part1_type: 'digits',
            part2_type: 'characters',
            part3_type: 'digits'
          })

        end

        def attr_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attr.human_name, back: attrs_location)
            end
            ::Stackable::List({
              active: 'sequences',
              items: items,
              location: back_location
            })
          end
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Schema::Attribute::Base,
            resource_id_key: :attr_id,
            path_prefix: path_prefix,
            location: attrs_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id], klass_id: match.params[:klass_id]},
          )
        end

        def schema_klass
          observe @schema_klass = Dynamic::Schema::Klass.includes({attrs: {include: {translations: 1, values: 1}}}).where(schema_id: match.params['schema_id']).find(match.params['klass_id'])
        end

        def edit_panel
          EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema, schema_attr: schema_attr, schema_klass: schema_klass)
        end

        class EditPanel < ::Settings::Schema::EditPanel
          param :schema_klass

          render { content }

          def header
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: I18n.t('shared.new'), back: back_location)
            end
          end

          def form
            Form(record: record) do
              Form::Element::Attribute::TranslatableString(
                attribute_name: 'human_name',
                errors_from: 'name',
                auto_focus: true,
              )
              Condition(schema_klass: schema_klass)
              Form::Element::Attribute::Integer(
                attribute_name: 'start_value',
                default_value: 1,
              )
              Form::Element::Attribute::String(
                attribute_name: 'format_example',
                value: @format_example || init_format_example,
                disabled: true
              )
              Form::Element::Attribute::String(
                attribute_name: 'prefix',
              ) do
              end.on(:change) do |value|
                @prefix = value
                @format_example = format_example
                mutate
              end
              Form::Element::Layout::Row() do
                Form::Element::Layout::Column(col_size: 'col-9') do
                  Form::Element::Attribute::Integer(
                    attribute_name: 'part1_length',
                    default_value: 5,
                    label: '',
                    label_col_size: 'col-md-4',
                    input_col_size: 'col-md-8',
                    min: 1
                  ) do
                  end.on(:change) do |value|
                    @part1_length = value.to_i
                    @format_example = format_example
                    mutate
                  end
                end
                Form::Element::Layout::Column() do
                  Form::Element::Attribute::Enum(
                    attribute_name: 'part1_type',
                    show_label: false
                  ) do
                    OPTION(value: 'digits') do
                      I18n.t('sequence.number')
                    end
                    OPTION(value: 'characters') do
                      I18n.t('sequence.character')
                    end
                  end.on(:change) do |value|
                    if value == 'characters'
                      @part2_type = 'digits'
                      @part3_type = 'characters'
                    else
                      @part2_type = 'characters'
                      @part3_type = 'digits'
                    end
                    @format_example = format_example
                    mutate
                  end
                end
              end
              Form::Element::Layout::Row() do
                Form::Element::Layout::Column(col_size: 'col-9') do
                  Form::Element::Attribute::Integer(
                    attribute_name: 'part2_length',
                    default_value: 0,
                    label_col_size: 'col-md-4',
                    input_col_size: 'col-md-8',
                    min: 0
                  ) do
                  end.on(:change) do |value|
                    @part2_length = value.to_i
                    @format_example = format_example
                    mutate
                  end
                end
                Form::Element::Layout::Column() do
                  Form::Element::Attribute::Enum(
                    attribute_name: 'part2_type',
                    value: @part2_type || record.part2_type,
                    show_label: false,
                    disabled: true
                  ) do
                    OPTION(value: 'digits') do
                      I18n.t('sequence.number')
                    end
                    OPTION(value: 'characters') do
                      I18n.t('sequence.character')
                    end
                  end
                end
              end
              Form::Element::Layout::Row() do
                Form::Element::Layout::Column(col_size: 'col-9') do
                  Form::Element::Attribute::Integer(
                    attribute_name: 'part3_length',
                    default_value: 0,
                    label_col_size: 'col-md-4',
                    input_col_size: 'col-md-8',
                    min: 0
                  )do
                  end.on(:change) do |value|
                    @part3_length = value.to_i
                    @format_example = format_example
                    mutate
                  end
                end
                Form::Element::Layout::Column() do
                  Form::Element::Attribute::Enum(
                    attribute_name: 'part3_type',
                    value: @part3_type || record.part3_type,
                    show_label: false,
                    disabled: true,
                  ) do
                    OPTION(value: 'digits') do
                      I18n.t('sequence.number')
                    end
                    OPTION(value: 'characters') do
                      I18n.t('sequence.character')
                    end
                  end
                end
              end
              Form::Element::Attribute::String(
                attribute_name: 'suffix',
              ) do
              end.on(:change) do |value|
                @suffix = value
                @format_example = format_example
                mutate
              end
              comment
            end.on(:success) do
              @format_example = nil
              @part2_type = nil
              @part3_type = nil
              App.history.push(record_location)
            end
          end

          def footer
            form_footer
          end

          def init_format_example
            @part2_type = record.part2_type
            @part1_length = record.part1_length || 5
            @part2_length = record.part2_length || 0
            @part3_length = record.part3_length || 0
            @prefix = record.prefix || ""
            @suffix = record.suffix || ""
            format_example
          end

          def format_example
            return if @part1_length < 0 || @part2_length < 0 || @part3_length < 0
            case @part2_type
            when 'digits'
              return @prefix + "A" * @part1_length + "0" * @part2_length + "A" * @part3_length + @suffix
            when 'characters'
              return @prefix + "0" * @part1_length + "A" * @part2_length + "0" * @part3_length + @suffix
            end
          end

          class Condition < HyperComponent

            param :form, default: nil
            param :record, default: nil
            param :prefix_path, default: []

            param :schema_klass, default: nil

            track_changes :record, :schema_klass

            after_new_params do
              if record_changed?
                init_submission_params
              end
            end

            def init_submission_params
              [
                'condition_type',
                'condition_attr_id',
                'condition_value_id',
                'condition_klass_id',
              ].each do |k|
                form.submission.write_from_db(prefix_path + [k], record.send(k))
              end
            end

            render do
              next unless ready?

              DIV(class: 'row form-group') do
                DIV(class: 'col-md-3') do
                  LABEL(class: 'col-form-label control-label') do
                    record.class.human_attribute_name(:condition_attr_id)
                  end
                end
                DIV(class: 'col-md-9 d-flex') do
                  DIV(class: 'flex-grow-1') do
                    SELECT(class: 'form-control', value: self.condition_attr_id_or_type) do
                      OPTION(value: '') do
                      end
                      enum_attrs.map do |attr|
                        OPTION(value: attr.id) do
                          attr.try(:human_name)
                        end
                      end
                      if klasses.any?
                        OPTION(value: 'type') do
                          'Type'
                        end
                      end
                    end.on(:change) do |event|
                      mutate self.condition_attr_id_or_type = event.target.value
                    end
                  end
                  DIV(class: 'px-2 d-flex') do
                    DIV(class: 'align-self-center') { '=' }
                  end
                  DIV(class: 'flex-grow-1') do
                    SELECT(class: 'form-control', value: self.condition_value_id_or_klass_id) do
                      OPTION(value: '') do
                      end
                      @enum_values&.map do |val|
                        OPTION(value: val.id) do
                          val.try(:human_name)
                        end
                      end
                    end.on(:change) do |event|
                      mutate self.condition_value_id_or_klass_id = event.target.value
                    end
                  end
                end
              end
            end

            def ready?
              return false unless form
              observe schema_klass
              observe subklasses
              return schema_klass.loaded? && subklasses.loaded?
            end

            def enum_attrs
              return @enum_attrs if @enum_attrs
              observe schema_klass.attrs
              if schema_klass.attrs.loaded?
                @enum_attrs = schema_klass.attrs.select{|a| a.type == "Enum"}
              else
                return []
              end
            end

            def klasses
              [schema_klass] + subklasses
            end

            def subklasses
              Dynamic::Schema::Klass.where(schema_id: schema_id, superklass_id: schema_klass.id).includes(translations: 1, except: [:options_for_indexed_json, :elasticsearch_mapping]).all
            end

            def schema_id
              schema_klass.schema_id || schema_klass.scope.dig(:where, :schema_id)
            end

            def condition_attr_id_or_type
              case self.condition_type
              when 'type'
                'type'
              when 'attr'
                self.condition_attr_id
              end
            end

            def condition_attr_id_or_type=(v)
              case v
              when 'type'
                self.condition_type = 'type'
                self.condition_attr_id = nil
                @enum_values = klasses
              when ''
                self.condition_type = 'none'
                self.condition_attr_id = nil
                @enum_values = []
              else
                self.condition_type = 'attr'
                self.condition_attr_id = v
                @enum_values = enum_attrs.detect{|attr| attr.id == v}&.values
              end

              self.condition_value_id = nil
              self.condition_klass_id = nil
            end

            def condition_value_id_or_klass_id
              case self.condition_type
              when 'none'
                @enum_values ||= []
                return nil
              when 'type'
                @enum_values ||= klasses
                return self.condition_klass_id
              when 'attr'
                @enum_values ||= enum_attrs.detect{|attr| attr.id == self.condition_attr_id}&.values
                return self.condition_value_id
              end
            end

            def condition_value_id_or_klass_id=(v)
              case self.condition_type
              when 'none'
                self.condition_value_id = nil
                self.condition_klass_id = nil
              when 'type'
                self.condition_value_id = nil
                self.condition_klass_id = v
              when 'attr'
                self.condition_value_id = v
                self.condition_klass_id = nil
              end
            end

            def condition_type
              form.submission.read(prefix_path + ['condition_type'])
            end

            def condition_type=(v)
              form.submission.write_from_user(prefix_path + ['condition_type'], v)
            end

            def condition_attr_id
              form.submission.read(prefix_path + ['condition_attr_id'])
            end

            def condition_attr_id=(v)
              form.submission.write_from_user(prefix_path + ['condition_attr_id'], v)
            end

            def condition_value_id
              form.submission.read(prefix_path + ['condition_value_id'])
            end

            def condition_value_id=(v)
              form.submission.write_from_user(prefix_path + ['condition_value_id'], v)
            end

            def condition_klass_id
              form.submission.read(prefix_path + ['condition_klass_id'])
            end

            def condition_klass_id=(v)
              form.submission.write_from_user(prefix_path + ['condition_klass_id'], v)
            end

          end

        end
      end
    end
  end
end
