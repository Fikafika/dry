class Settings
  class Schema
    class Cascades < Klasses::Base

      render { content }

      def content
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
        schema_klass
      end

      def edit_panel
        EditPanel(record: current_model, path: "", schema: schema)
      end

      class EditPanel < ::Settings::Schema::EditPanel
        param :schema

        render { content }

        def header
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: ::Dynamic::Schema::Cascade::Base.model_name.human, back: back_location)
          end
        end

        def form
          DeduplicationKeysForm(record: record, schema: schema)
        end

        def footer
          DIV(class: 'pr-3 pl-3 pt-3') do
            Form::ErrorMessage()
            Form::Footer()
          end
        end

        def back_location
          request.location.pathname.gsub('/cascades', '')
        end

        class DeduplicationKeysForm < HyperComponent
          param :schema
          param :record

          render do
            initialize_record
            next unless record.loaded? && schema.loaded?
            init_deduplication_keys
            content
          end

          def content
            DIV do
              Form(record: record, enable_after_user_interaction: true) do
                render_deduplication_keys
                render_available_associations_keys
              end.on(:success) do
                reset
                mutate
              end.on(:cancel) do
                reset
                mutate
              end
            end
          end

          def render_deduplication_keys
            @deduplication_keys&.each do |path, element|
              render_deduplication_key(path, element)
            end
          end

          def render_deduplication_key(path, element)
            current_klass = klasses_by_id(path[:klass_id])
            DIV(class: 'd-flex flex-row justify-content-between align-items-center') do
              association_key_item(path, element)
              remove_btn(path, element) if element[:editable]
            end
            render_deduplication_key_content(path, element, current_klass)
            HR{}
          end

          def render_deduplication_key_content(path, element, current_klass)
            klass = klasses_by_id(element[:assoc]&.target_klass_id) || current_klass
            DeduplicationKeys(
              klass: klass,
              keys: element[:keys],
              attrs: element[:available_attrs],
              mapped_attrs: element[:mapped_attrs],
              key: path.to_s + element[:cascade]&.id.to_s + @timestamp.to_s,
              editable: element[:editable],
            ).on(:change) do |keys|
              next unless element[:editable]
              change_keys(path, element, keys)
            end
          end

          def change_keys(path, element, keys)
            element[:keys] = keys
            Form.current.submission.write_from_user(['record', 'cascades_attributes'], compute_cascades_params(path))
            Form.current.enable
          end

          def render_available_associations_keys
            available_associations_keys.each do |path, element|
              DIV(class: 'd-flex flex-row') do
                association_key_item(path, element)
                DIV(class: 'd-flex flex-fill') do
                end
                BUTTON(class:"btn btn-transparent btn-light btn-sm", type: 'button') do
                  I(class: 'fa fa-pencil fa-fw')
                end.on(:click) do |event|
                  event.prevent_default
                  add_association_key(path, element)
                end
              end
              HR{}
            end
          end

          def association_key_item(path, element)
            current_klass = klasses_by_id(path[:klass_id])
            DIV do
              SPAN(class: 'h5 mb-0') do
                current_klass&.model_name&.human
              end
              if path[:assoc_id]
                I(class: 'mx-1 align-self-center fa fa-chevron-right fa-fw')
                SPAN(class: 'h5 mb-0') do
                  current_klass.human_attribute_name(element[:assoc].name)
                end
              end
            end
          end

          def remove_btn(path, element)
            A(href: "#remove", class: 'm-0 btn btn-transparent btn-light btn-sm') do
              I(class: "fa fa-trash-alt")
            end.on(:click) do |event|
              event.prevent_default
              remove_association_key(path, element)
            end
          end

          def add_association_key(path, element)
            element[:editable] = true
            @deduplication_keys[path] = element
            mutate
          end

          def remove_association_key(path, element)
            if element[:cascade]&.id
              @computed_cascades_params[path] = {
                id: element[:cascade].id,
                _destroy: true,
              }
            else
              @computed_cascades_params.delete(path)
            end
            @deduplication_keys.delete(path)
            Form.current.submission.write_from_user(['record', 'cascades_attributes'], @computed_cascades_params.values)
            Form.current.enable
            mutate
          end

          def compute_cascades_params(params)
            element = @deduplication_keys[params]
            @computed_cascades_params[params] = {
              id: element[:cascade]&.id,
              schema_id: schema.id,
              klass_id: params[:klass_id],
              klass_name: klasses_by_id(params[:klass_id]).name,
              assoc_id: params[:assoc_id],
              association_name: element[:assoc]&.name,
              keys: element[:keys],
              _destroy: element[:keys].empty?,
            }
            @computed_cascades_params.values
          end

          def init
            @available_keys = nil
            @deduplication_keys = nil
            @computed_cascades_params = nil
            @timestamp ||= 0;  @timestamp += 1
          end

          def initialize_record
            observe record
            observe schema
            if record != @previous_record
              init
              @previous_record = record
            end
          end

          def init_deduplication_keys
            if @deduplication_keys.nil?
              @deduplication_keys = {}
              @computed_cascades_params = {}
              record.cascades.each do |cascade|
                _assoc = associations_by_id(cascade.assoc_id)
                _klass = schema.klasses_by_id[_assoc&.target_klass_id] || record_klass
                @deduplication_keys[{ klass_id: cascade.klass_id, assoc_id: cascade.assoc_id }] = {
                  keys: cascade.keys,
                  cascade: cascade,
                  assoc: _assoc,
                  available_attrs: attrs_for(_klass),
                  editable: true,
                }
              end
            end
          end

          def reset
            init
            init_deduplication_keys
          end

          def available_associations_keys
            @available_keys ||= {}
            if @available_keys.empty?
              @available_keys[{ klass_id: record.id, assoc_id: nil }] = { keys: [], available_attrs: attrs_for(record_klass) }
              record_klasses = record_klass.associations.select {|assoc| !assoc.target_klass.nil?}.sort_by(&:human_name).each do |as|
                _klass = schema.klasses_by_id[as.target_klass_id]
                @available_keys[{ klass_id: record.id, assoc_id: as.id}] = { keys: [], assoc: as, available_attrs: attrs_for(_klass) }
              end
            end
            @available_keys.reject { |path, _| @deduplication_keys.key?({ klass_id: path[:klass_id], assoc_id: path[:assoc_id] }) }
          end

          def associations_by_id(id)
            record_klass.associations.detect { |assoc| assoc.id == id }
          end

          def klasses_by_id(id)
            schema.klasses_by_id[id]&.const
          end

          def record_klass
            schema.klasses_by_id[record.id]
          end

          def attrs_for(current_record)
            current_record.attrs.sort_by(&:human_name).map(&:name) + current_record.associations.sort_by(&:human_name).map(&:name)
          end
        end
      end
    end
  end
end
