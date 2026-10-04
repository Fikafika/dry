class Settings
  class Schema
    class EmailOrder
      class Base < Klasses::Base

        render { content }

        def content
          observe schema

          if schema.constants_loaded? && schema.has_feature_enabled?('Dynamic::Communication::Feature')
            super
          else
            DIV() do
            end
          end
        end

        def klass
          schema.const::R::EmailOrder::Base
        end

        def new_record
          klass.new({
            schema_id: match.params['schema_id'],
            klass_id: match.params['klass_id'],
          })
        end

        def self.includes_for_show
          {
            include: {
              types: 1,
            },
          }
        end

        def scope_for_all
          {
            "schema" => schema.name.downcase,
            "klass" => match.params['klass_id'].pluralize,
          }
        end

        def self.children_items
          []
        end

        class Filters < Form::Element::Base

          param :record_klass
          param :root_klass

          def render_input
            observe record_klass.options_for_indexed_json

            DIV(class: 'row form-group') do
              LABEL(class: 'col-md-3 control-label') do
                'Filter'
              end
              DIV(class: 'col-md-9') do
                if record_klass.options_for_indexed_json.loaded?
                  value = form.submission.read(path)
                  if @list.blank? || value != @old_value
                    @list = ::Crm::Filters::AdvancedList.convert_from_hash(value, record_klass, name_without_brackets: true, normalize: true)
                    @old_value = value
                  end
                  ::Crm::Filters::AdvancedList(list: @list, klass: record_klass, root_klass: root_klass, get_variable: nil, depth: 0, default_menu: ["contains", "not_contains", "empty", "not_empty"]).on(:change) do |list|
                    @list = list
                    converted_list = convert_list_with_uuids(list)
                    hash = ::Crm::Filters::AdvancedList.convert_to_hash(converted_list, name_without_brackets: true, simplify: true)
                    change_value(hash)
                    @old_value = hash
                    form.mutate
                  end
                end
              end
            end
          end

          def convert_list_with_uuids(list)
            uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
            list_with_fix = []
            list.each do |l|
              list_with_fix_tmp = []
              l[2].each do |l_|
                value = l_[2]
                if value.is_a? Array
                  value = value[0]
                end
                if uuid_regex.match?(value)
                  if l_[1].start_with? "contains"
                    l_[1] = "contains_id"
                  else
                    l_[1] = "not_contains_id"
                  end
                end
                list_with_fix_tmp << l_
              end
              list_with_fix << [l[0], l[1], list_with_fix_tmp]
            end
            return list_with_fix
          end

        end

        class AddButton < Form::Element::Control::AddButton
          def render_input
            DIV(ref: _ref, class: 'row') do
              DIV(class: 'col text-right') do
                A(href: "#add", class: "btn btn-light") do
                  text || I18n.t('shared.add')
                end.on(:click) do |event|
                  event.prevent_default
                  values = form.submission.read_association(path) || []
                  values << new_record_attrs
                  form.submission.write_association(path, values)
                  position = 0
                  while form.submission.values.keys.include?(["base", "types", position, "position"])
                    position += 1
                  end
                  if position > 0
                    form.submission.values[["base", "types", position, "position"]] = form.submission.values[["base", "types", position - 1, "position"]] + 1
                  else
                    form.submission.values[["base", "types", position, "position"]] = position
                  end
                  form.mutate
                  form.enable
                end
              end
            end
          end
        end

        class EditPanel < ::Settings::Schema::EditPanel

          render { content }

          def record_klass
            "D::#{schema.name.classify_permalink}::#{klass.classify}".safe_constantize
          end

          def form
            Form(record: record) do
              Form::Element::Attribute::String(
                attribute_name: 'schema',
                default_value: schema.name.downcase,
                editor: 'hidden',
              )
              Form::Element::Attribute::String(
                attribute_name: 'klass',
                default_value: klass.pluralize,
                editor: 'hidden',
              )
              Form::Element::Attribute::String(
                attribute_name: 'name',
              )

              Form::Element::Association::HasMany(attribute_name: 'types', mode: 'nested_form') do
                Form::Element::Attribute::Enum(attribute_name: 'tag', possible_values: possible_values_emails)
                # Form::Element::Association::BelongsTo(attribute_name: 'value_record', target_klass: target_klass, polymorphic: true)
              end
              AddButton(attribute_name: 'types')

              Filters(attribute_name: 'filters', record_klass: record_klass, root_klass: record.root_klass)
              children_list
            end.on(:change) do |f|
              @current_form = f
              @activate_footer = true
              mutate
            end.on(:success) do
              App.history.push(record_location)
            end
          end

          def footer
            DIV(class: 'pr-3 pl-3 pt-3') do
              if @activate_footer
                if @current_form.navigation_count == 0
                  Form::Element::Control::Navigation(form: @current_form, timestamp: timestamp, buttons_automatically_shown: true) do
                    children.render
                  end
                else
                  children.render
                end
              else
                disabled_buttons
              end
            end
          end

          def disabled_buttons
            DIV(class: 'row') do
              DIV(class: 'col') do
                DIV class: 'btn-toolbar justify-content-between pb-3' do
                  DIV do
                  end
                  DIV do
                    BUTTON class: "btn btn-light disabled text-capitalize-first-letter" do
                      I18n.t('form.cancel')
                    end
                    BUTTON class: "btn btn-primary ml-2 disabled" do
                      SPAN(class: 'text-capitalize-first-letter') do
                        I18n.t('form.submit')
                      end
                    end
                  end
                end
              end
            end
          end

          def timestamp
            @timestamp ||= 0
            @timestamp += 1
          end

          def klass
            path.split('/')[5]
          end

          def possible_values_emails
            "::#{schema.const}::Email".safe_constantize.attributes["tag"]['possible_values'][I18n.locale]
          end

          def queries
            observe "::#{schema.const}::R::Query::Saved".safe_constantize.where(path: query_path).all
          end

          def query_path
            "/crm/#{schema.name.underscore}/table/#{klass.pluralize}"
          end

        end

      end

    end

  end

end
