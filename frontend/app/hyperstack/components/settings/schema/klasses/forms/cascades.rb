class Settings
  class Schema
    class Forms
      class Cascades < ::Settings::Schema::Klasses::Base
        before_update do
          if schema_form&.not_found?
            App.history.push(forms_location)
          end
        end

        render do
          observe_models
          update_recents
          layout(layout_page_count) do
            if request.params[:action] == 'index'
              parent_parent_page
              parent_page(active: resources_name)
              edit_page
            else
              parent_page(active: resources_name)
              edit_page
            end
          end
        end

        def current_model
          schema_form
        end

        def schema_form
          observe @schema_form_klass = Dynamic::Form.includes({include: {cascades: 1, elements: {includes: {translations: 1}}}}).where({
            schema_id: match.params['schema_id'],
            id: match.params['form_id']
          }).first
        end

        def edit_panel
          EditPanel(record: current_model, path: "", schema: schema, back_location: back_location)
        end

        class EditPanel < ::Settings::Schema::EditPanel
          param :schema
          param :back_location

          render { content }

          def header
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: ::Dynamic::Cascade.model_name.human, back: back_location)
            end
          end

          def form
            observe record
            return unless record.loaded?
            DeduplicationKeysForm(record: record, schema: schema)
          end

          def footer
            return unless record.loaded?
            DIV(class: 'pr-3 pl-3 pt-3') do
              Form::ErrorMessage()
              Form::Footer()
            end
          end

          class DeduplicationKeysForm < Settings::Schema::Cascades::EditPanel::DeduplicationKeysForm

            def init_deduplication_keys
              return unless schema_cascades.loaded?

              if @deduplication_keys.nil?
                @computed_cascades_params = {}
                compute_available_keys
                @deduplication_keys = {}
                @available_keys.each do |path, element|
                  cascade = record.cascades.detect{|c| c.klass_id == path[:klass_id] && c.assoc_id == path[:assoc_id]}
                  cascade_from_schema = schema_cascade_for(path)
                  cascade ||= cascade_from_schema
                  next unless cascade
                  assoc = associations_by_id(path[:klass_id], path[:assoc_id])

                  inverse_of = assoc&.inverse_of_id ? associations_by_id(assoc.target_klass_id, assoc.inverse_of_id)&.name : nil

                  is_cascade_from_schema = cascade == cascade_from_schema

                  @deduplication_keys[path] = {
                    keys: cascade.keys,
                    cascade: cascade,
                    cascade_from_schema: cascade_from_schema,
                    available_attrs: available_attrs(path, is_cascade_from_schema),
                    mapped_attrs: mapped_attrs(path),
                    assoc: assoc,
                    inverse_of: inverse_of,
                    editable: !is_cascade_from_schema
                  }
                  compute_error_message(path)
                end
                compute_available_attribute
              end
            end

            def available_attrs(path, from_schema = false)
              if from_schema
                assoc = associations_by_id(path[:klass_id], path[:assoc_id])
                klass = schema.klasses_by_id[path[:assoc_id] ? assoc&.target_klass_id : path[:klass_id]]
                attrs_for(klass)
              else
                @available_keys.dig(path, :available_attrs) || Set.new
              end
            end

            def mapped_attrs(path)
              @available_keys.dig(path, :available_attrs)
            end

            def schema_cascades
              observe @schema_cascades ||= Dynamic::Cascade.where(schema_id: schema.name.underscore, owner_id: [record.id, nil]).all
            end

            def available_associations_keys
              return [] unless @available_keys
              @available_keys.reject { |path, _| @deduplication_keys.key?({ klass_id: path[:klass_id], assoc_id: path[:assoc_id] })}
            end

            def editable_deduplication_keys?(element)
              !cascade_from_schema?(element)
            end

            def cascade_from_schema?(element)
              element[:cascade_from_schema] && element[:cascade] == element[:cascade_from_schema]
            end

            def render_deduplication_key_content(path, element, current_klass)
              if error_message(path)
                error_message_box { error_message(path) }
              end

              from_schema = cascade_from_schema?(element)
              super
              if from_schema || element[:cascade_from_schema]
                DIV(class: 'd-flex') do
                  DIV(class: 'd-flex flex-grow-1') {}
                  BUTTON(class:"btn btn-transparent btn-light", type: 'button') do
                    if from_schema
                      I18n.t('settings.klasses.forms.cascades.override')
                    elsif element[:cascade_from_schema]
                      I18n.t('settings.klasses.forms.cascades.undefined')
                    end
                  end.on(:click) do |event|
                    event.prevent_default
                    if from_schema
                      add_association_key(path, element)
                    else
                      remove_association_key(path, element)
                    end
                  end
                end
              end
            end

            def change_keys(path, element, keys)
              super
              compute_error_message(path)
              if error_message_changed?(path)
                store_previous_error_message(path)
                mutate
              end
            end

            def compute_error_message(path)
              if could_modify_wrong_record?(path)
                @deduplication_keys[path][:error_message] = I18n.t('settings.klasses.forms.cascades.could_modify_wrong_record')
              elsif could_create_duplicates?(path)
                @deduplication_keys[path][:error_message] = I18n.t('settings.klasses.forms.cascades.could_create_duplicates')
              else
                @deduplication_keys[path][:error_message] = nil
              end
            end

            def error_message(path)
              @deduplication_keys.dig(path, :error_message)
            end

            def error_message_changed?(path)
              @previous_error_message&.[](path) != error_message(path)
            end

            def store_previous_error_message(path)
              @previous_error_message ||= {}
              @previous_error_message[path] = error_message(path)
            end

            def could_modify_wrong_record?(path)
              return false unless any_key?(path)
              c = @deduplication_keys.dig(path, :cascade_from_schema)
              return false unless c # can't know
              return false if c == @deduplication_keys.dig(path, :cascade) # use cascade from schema
              keys = @deduplication_keys.dig(path, :keys)
              inverse_of = @deduplication_keys.dig(path, :inverse_of)

              # if any level is included in a level of the cascade from schema
              r = keys.detect do |l|
                next false unless l&.any?
                c.keys.detect do |l_|
                  if inverse_of # don't take account of inverse association
                    l_ = l_.select{|a| a != inverse_of}
                    l = l.select{|a| a != inverse_of}
                  end
                  l_.length > l.length && l.all?{|a| l_.include?(a)}
                end
              end
              r
            end

            def any_key?(path)
              @deduplication_keys.dig(path, :keys)&.detect{|l| l.any?}
            end

            def error_message_box
              DIV(class: 'alert alert-danger my-2') do
                yield
              end
            end

            def could_create_duplicates?(path)
              return true unless any_key?(path)
              keys = @deduplication_keys.dig(path, :keys)
              mapped = mapped_attrs(path)
              return keys.all?{|l| l&.any?{|a| !mapped.include?(a) } }
            end

            def add_association_key(path, element)
              if element[:cascade_from_schema]
                element[:editable] = true
                element.delete(:cascade)
                element[:keys] = []
                element[:available_attrs] = available_attrs(path)
                compute_error_message(path)
                store_previous_error_message(path)
              end
              super
            end

            def remove_btn(path, element)
              # no remove btn
            end

            def remove_association_key(path, element)
              if element[:cascade_from_schema]
                to_destroy = element[:cascade]&.id
                if to_destroy
                  @computed_cascades_params[path] = {
                    id: to_destroy,
                    _destroy: true,
                  }
                end
                element[:cascade] = element[:cascade_from_schema]
                element[:editable] = false
                element[:keys] = element[:cascade_from_schema].keys.deep_dup
                element[:available_attrs] = available_attrs(path, true)
                compute_error_message(path)
                store_previous_error_message(path)
                Form.current.submission.write_from_user(['record', 'cascades_attributes'], @computed_cascades_params.values)
                Form.current.enable
                mutate
              else
                super
              end
            end

            def schema_cascade_for(path)
              r = schema_cascades_by_klass_id_and_assoc_id[path]
              return r if r
              return unless path[:klass_id] && path[:assoc_id]
              assoc = associations_by_id(path[:klass_id], path[:assoc_id])
              return unless assoc
              alternative_path =  {klass_id: assoc.target_klass_id, assoc_id: nil}
              return schema_cascades_by_klass_id_and_assoc_id[alternative_path]
            end

            def schema_cascades_by_klass_id_and_assoc_id
              return {} unless schema_cascades.loaded?
              return @schema_cascades_by_klass_id_and_assoc_id if @schema_cascades_by_klass_id_and_assoc_id
              result = {}
              schema_cascades.each do |c|
                k = {klass_id: c.klass_id, assoc_id: c.assoc_id}
                result[k] = c
              end
              @schema_cascades_by_klass_id_and_assoc_id = result
              return result
            end

            def compute_available_keys
              @available_keys ||= {}
              return unless @available_keys.empty?

              record.elements.each do |element|
                next unless is_record_element(element.type)
                compute_element_attrs(element)
              end
            end

            def compute_available_attribute
              @available_keys.each do |path, element|
                next unless @deduplication_keys.key?(path)
                @deduplication_keys[path][:available_attrs] = (element[:available_attrs] + @deduplication_keys[path][:available_attrs]).uniq
              end
            end

            def is_record_element(item)
              item.start_with?("Association::") || item.start_with?("Attribute::")
            end

            def compute_element_attrs(element)
              k = element.root_klass_name.safe_constantize
              method_names = element.method_names
              assoc = nil
              preview_klass = nil
              method_names.each do |method_name|
                assoc = k.reflect_on_association(method_name)
                preview_klass = k
                k = assoc.klass
              end
              preview_klass ||= k
              _klass = d_schema_klass(preview_klass)
              _assoc = association_from_name(_klass, assoc&.name)
              _path = { klass_id: _klass.id, assoc_id: _assoc&.id }
              inverse_of = assoc&.options&.[](:inverse_of)
              @available_keys[_path] ||= { keys: [], available_attrs: [], assoc: _assoc, editable: true, inverse_of: inverse_of }
              unless @available_keys[_path][:available_attrs].include?(element.attribute_name)
                @available_keys[_path][:available_attrs] << element.attribute_name
              end
              if inverse_of && !@available_keys[_path][:available_attrs].include?(inverse_of)
                @available_keys[_path][:available_attrs] << inverse_of
              end
            end

            def compute_cascades_params(path)
              element = @deduplication_keys[path]
              @computed_cascades_params[path] = {
                id: element[:cascade]&.id,
                owner_id: record.id,
                owner_type: record.class,
                schema_id: schema.id,
                klass_id: path[:klass_id],
                klass_name: klasses_by_id(path[:klass_id]).name,
                assoc_id: path[:assoc_id],
                association_name: element[:assoc]&.name,
                keys: element[:keys],
                _destroy: element[:keys].empty?,
              }
              @computed_cascades_params.values
            end

            def d_schema_klass(klass_name)
              schema.klasses_by_id.values.find { |sk| sk.name == klass_name.name.split('::').last }
            end

            def association_from_name(klass, name)
              klass.associations.select { |sa| sa.name == name}.first
            end

            def associations_by_id(klass_id, assoc_id)
              schema.klasses_by_id[klass_id].associations.select { |ass| ass.id == assoc_id }.first
            end
          end
        end

        def parent_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_form.human_name, back: back_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::Forms.children_items(schema),
              location: back_location
            })
          end
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Form,
            resource_id_key: :form_id,
            path_prefix: path_prefix,
            location: forms_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id], klass_name: schema_klass_name},
          )
        end

        def forms_location
          "#{schema_location}/klasses/#{match.params['klass_id']}/forms"
        end

        def back_location
          "#{forms_location}/#{match.params['form_id']}"
        end
      end
    end
  end
end
