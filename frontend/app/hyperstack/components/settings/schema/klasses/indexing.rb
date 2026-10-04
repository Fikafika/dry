class Settings
  class Schema
    class Indexing < Klasses::Base

      render { content }

      def self.feature
        'Dynamic::Elasticsearch::Feature'
      end

      def self.icon
        ::Dynamic::Elasticsearch.icon
      end

      def self.model_name
        ::Dynamic::Elasticsearch.model_name
      end

      def self.resources_name(klass = self, plural = false) # bidouille TODO find a better way to make settings for something that is not a hyper_resource
        'indexing'
      end

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
        EditPanel(record: current_model, path: '', schema: schema)
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def header
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: ::Dynamic::Elasticsearch.model_name.human, back: back_location)
          end
        end

        def form
          init
          if record.loaded? && record.superklass_id.present?
            DIV(class: 'alert alert-info') do
              DIV do
                I18n.t('settings.klasses.indexing.settings_on_baseklass')
              end
              Link("/crm/#{schema.name.underscore}/settings/klasses/#{baseklass.name.underscore}/indexing") do
                baseklass.human_name
              end
            end
          else
            Form(record: record, enable_after_user_interaction: true) do
              indexed_fields
              global_search_fields
            end.on(:success) do
              @field_count = nil
              @options_for_indexed_json = nil
              @previous_checkeds = nil
              compute_options_for_indexed_json
              mutate
            end
          end
        end

        def init
          observe record
          if record != @previous_record
            reset
            @previous_record = record
          end
        end

        def reset
          @field_count = nil
          @collapsable_shown = nil
          @previous_checkeds = nil
          @options_for_indexed_json = nil
          @klasses_preloaded = nil
          @checkeds = nil

          @global_search_checkeds = nil
          @global_search_collapsable_shown = nil

          Checkbox.reset_all_checkboxes
        end

        def baseklass
          schema.klasses.detect{|k| k.id == record.baseklass_id}
        end

        # ---------------------------------

        def indexed_fields
          DIV(class: 'pb-2 d-flex') do
            DIV(class: 'flex-grow-1', dangerously_set_inner_HTML: { __html: I18n.t('settings.klasses.indexing.indexed_fields.explaination') })
            indexed_fields_count
          end
          Tree(
            klass: record_klass,
            schema: schema_,
            checkeds: checkeds,
            collapsable_shown: collapsable_shown,
            checkbox_of_collapsable_are_disabled: false,
          ).on(:change) do
            Form.current.submission.write_from_user(['record', 'options_for_indexed_json'], compute_options_for_indexed_json)
            if Form.current.submission.params.dig('record','options_for_indexed_json') != record.options_for_indexed_json
              Form.current.enable
            end
            mutate
          end
        end

        def indexed_fields_count
          if @field_count
            DIV(class: "#{'text-danger' if @field_count > elasticsearch_mapping_field_limit}") do
              "#{@field_count} / #{elasticsearch_mapping_field_limit}"
            end
          else
            if record&.loaded? && record_klass&.loaded?
              after(0) do
                compute_options_for_indexed_json
                mutate
              end
            end
          end
        end

        def checkeds
          return {} unless record.loaded?
          @checkeds ||= compute_checkeds
        end

        def compute_checkeds(path = nil, options = record.options_for_indexed_json, result = {})
          return result unless options

          options['only']&.each do |k|
            result[[path, k].compact.join('.')] = true
          end
          options['include']&.each do |k, v|
            result[[path, k].compact.join('.')] = true
            next if v.dig('include', 'attachment') || v.dig('include', 'attachments') # workaround attachments
            compute_checkeds([path, k].compact.join('.'), v, result)
          end
          return result
        end

        def collapsable_shown
          @collapsable_shown ||= {}
        end

        def record_klass
          schema_.klasses_by_id[record.id]
        end


        def schema_
          observe s = Dynamic::Schema.includes(Dynamic::Schema.includes_for_load).find(request.params[:schema_id])
          @klasses_preloaded = s.klasses_preloaded if s.loaded? && !@klasses_preloaded # TODO how to preload automatically ?
          s
        end

        def compute_options_for_indexed_json
          @options_for_indexed_json ||= {'only' => klass_default_attributes}
          @previous_checkeds ||= []

          @to_add = checkeds.keys - @previous_checkeds
          @to_remove = @previous_checkeds - checkeds.keys

          @field_count ||= klass_default_attributes.map{|a| elasticsearch_mapping_field_count(a) }.sum

          @to_add.each do |path|
            klass = schema_.klasses_by_id[record.id]
            path_ = path.split('.')
            r = @options_for_indexed_json
            path_.each_with_index do |k, i|
              a = klass&.attr_attachment_or_association(k)
              case a
              when Dynamic::Schema::Association::Base
                klass = a&.target_klass
                r['include'] ||= {}
                unless r['include'][k]
                  @field_count += elasticsearch_mapping_field_count(a)
                  r['include'][k] = {'only' => klass ? default_attributes : polymorphic_association_default_attributes}
                end
                r = r['include'][k]
              when Dynamic::Schema::Attachment::Base
                r['include'] ||= {}
                unless r['include'][k]
                  @field_count += elasticsearch_mapping_field_count(a)
                  r['include'][k] = default_attachment_include(a)
                end
              when Dynamic::Schema::Attribute::Base, nil
                unless r['only']
                  r['only'] = default_attributes
                  @field_count += default_attributes.map{|d| elasticsearch_mapping_field_count(d) }.sum
                end
                unless r['only'].include?(k)
                  @field_count += elasticsearch_mapping_field_count(a || k)
                  r['only'] << k
                end
              end
            end
          end

          @to_remove.each do |path|
            klass = schema_.klasses_by_id[record.id]
            path_ = path.split('.')
            r = @options_for_indexed_json
            a = nil
            path_.each_with_index do |k, i|
              a = klass&.attr_attachment_or_association(k)
              case a
              when Dynamic::Schema::Association::Base
                klass = a&.target_klass
                if i != path_.length - 1
                  r = r['include'].try(:[], k)
                end
                break unless r
              else
                break
              end
            end
            next unless r
            k = path_.last
            if r['only']&.include?(k)
              @field_count -= elasticsearch_mapping_field_count(a || k)
              r['only'].delete(k)
            end
            if r.dig('include', k)
              c = elasticsearch_mapping_field_count(a || k)
              @field_count -= c
              r['include'].delete(k)
              r.delete('include') if r['include'].empty?
            end
          end

          @previous_checkeds = checkeds.keys.dup

          #`console.log(#{@options_for_indexed_json.to_n})`

          return @options_for_indexed_json
        end

        def elasticsearch_mapping_field_count(a)
          r = case a
          when Dynamic::Schema::Attribute::String
            2 # attr + attr.keyword
          when Dynamic::Schema::Attribute::Enum
            2 # attr + attr.keyword
          when Dynamic::Schema::Association::Base
            1 + (a.target_klass_id ? default_attributes : polymorphic_association_default_attributes).map{|d| elasticsearch_mapping_field_count(d) }.sum
          when Dynamic::Schema::Attachment::Base
            0 # currently not searchable. should we search on filename ?
          when 'id', 'type'
            2
          when *indexable_virtual_attributes.keys
            t = indexable_virtual_attributes.dig(a, :type)
            k = "Dynamic::Schema::Attribute::#{t.classify}".safe_constantize
            elasticsearch_mapping_field_count(k&.new)
          when 'updated_at', 'created_at', 'deleted_at'
            1
          else
            0
          end
          return r
        end

        def indexable_virtual_attributes
          Dynamic::Elasticsearch::Feature::DynamicRecord.indexable_virtual_attributes
        end

        def default_attributes
          ['id', 'type', 'created_at', 'updated_at', 'deleted_at']
        end

        def klass_default_attributes
          default_attributes
        end

        def polymorphic_association_default_attributes
          default_attributes + ['polymorphic_name']
        end

        def default_attachment_include(a)
          case a
          when Dynamic::Schema::Attachment::HasOne
            {only: ['name'], include: {'attachment' => {'include' => {'filename' => {}, 'signed_id' => {}}}}}
          when Dynamic::Schema::Attachment::HasMany
            {only: ['name'], include: {'attachments' => {'include' => {'filename' => {}, 'signed_id' => {}}}}}
          end
        end

        def elasticsearch_mapping_field_limit
          1000 # default value in elasticsearch
        end

        # -----------------------------------

        def global_search_fields
          DIV(class: 'pt-2 pb-2',  dangerously_set_inner_HTML: { __html: I18n.t('settings.klasses.indexing.global_search_fields.explaination') })
          Tree(
            klass: record_klass,
            schema: schema_,
            checkeds: global_search_checkeds,
            collapsable_shown: global_search_collapsable_shown,
            checkbox_of_collapsable_are_disabled: false,
          ).on(:change) do
            Form.current.submission.write_from_user(['record', 'global_search_fields'], global_search_checkeds.keys)
            if Form.current.submission.params.dig('record','global_search_fields') != record.global_search_fields
              Form.current.enable
            end
            mutate
          end
        end

        def global_search_checkeds
          return {} unless record.loaded?
          @global_search_checkeds ||= compute_global_search_checkeds_from_record
        end

        def compute_global_search_checkeds_from_record
          result = {}
          record.global_search_fields.each do |k|
            result[k] = true
          end
          return result
        end

        def global_search_collapsable_shown
          @global_search_collapsable_shown ||= {}
        end

        def footer
          DIV(class: 'pr-3 pl-3 pt-3') do
            Form::ErrorMessage()
            Form::Footer() do
              reindex_btn
            end
          end
        end

        def reindex_btn
          BUTTON class: "btn btn-light-yiq" do
            I18n.t('settings.klasses.indexing.launch')
          end.on(:click) do |event|
            event.prevent_default
            record.reindex
          end
        end

        class Tree < HyperComponent

          param :klass
          param :schema
          param :path, default: nil
          param :collapsable_shown, default: {}
          param :checkeds, default: {}
          param :checkbox_of_collapsable_are_disabled, default: false
          param :additional_check, default: true

          fires :change

          render do
            next unless klass && schema.loaded?

            attrs_and_attachments = (klass.all_attrs_assocs_attachs + indexable_virtual_attributes).select do |a|
              a.is_a?(Dynamic::Schema::Attribute::Base) || a.is_a?(Dynamic::Schema::Attachment::Base) || a.is_a?(OpenStruct)
            end.sort_by(&:human_name).map{|a| {label: a.human_name, path: [path, a.name].compact.join('.')}}
            checkboxes(attrs_and_attachments, checkeds: checkeds)

            klass.all_attrs_assocs_attachs.select do |a|
              a.is_a?(Dynamic::Schema::Association::Base)
            end.sort_by(&:human_name).each do |a|
              a_path = [path, a.name].compact.join('.')
              DIV(class: 'd-flex align-items-center flex-grow-1') do
                I(class: "mr-2 fa-fw fas fa-#{collapsable_shown[a_path] ? 'minus' : 'plus'} cursor-pointer") do
                end.on(:click) do |event|
                  collapsable_shown[a_path] = !collapsable_shown[a_path]
                  mutate
                end
                Checkbox(
                  label: a.human_name,
                  path: a_path,
                  checkeds: checkeds,
                  show_count: true,
                  additional_paths_to_check: additional_paths_to_check(a, a_path),
                  disabled: checkbox_of_collapsable_are_disabled,
                  check_ancestors: additional_check,
                ).on(:change) do
                  change!
                end
              end
              if collapsable_shown[a_path]
                DIV(style: {marginLeft: "1.6em"}) do # TODO css class
                  Tree(
                    klass: a.target_klass,
                    schema: schema,
                    collapsable_shown: collapsable_shown,
                    path: a_path,
                    checkeds: checkeds,
                    checkbox_of_collapsable_are_disabled: checkbox_of_collapsable_are_disabled,
                    additional_check: additional_check,
                  ).on(:change) do
                    change!
                  end
                end
              end
            end
          end

          def indexable_virtual_attributes
            @indexable_virtual_attributes ||= Dynamic::Elasticsearch::Feature::DynamicRecord.indexable_virtual_attributes.select{|k, v| !v[:included_by_default]}.keys.map do |k|
              OpenStruct.new(name: k, human_name: I18n.t("activerecord.defaults.attributes.#{k}"))
            end
          end

          def additional_paths_to_check(association, path)
            return [] unless additional_check
            result = []
            target_klass = association.target_klass
            if target_klass
              n = target_klass.name_attribute&.name
              result << "#{path}.#{n}" if n
              p = target_klass.photo_attachment&.name
              result << "#{path}.#{p}" if p
            else
              result << "#{path}.polymorphic_name"
            end
            return result
          end

          def checkboxes(columns)
            DIV(style: path ? {marginLeft: "0.5em", paddingLeft: "1em", borderLeft: '2px solid black'} : {paddingLeft: "1.7em"}) do # TODO css class
              # mediaquery: 2-col layout for lg
              DIV(class: "d-none d-xl-flex row") do
                group_list_2 = columns.in_groups(2, false).each do |subgroup|
                  subgroup.each do |column|
                    DIV(class: "col-6") do
                      Checkbox(label: column[:label], path: column[:path], checkeds: checkeds).on(:change) do
                        change!
                      end
                    end
                  end
                end
              end
              # mediaquery: 1-col layout for xs
              DIV(class: "d-xs-flex d-xl-none row") do
                columns.each do |column|
                  DIV(class: "col-12") do
                    Checkbox(label: column[:label], path: column[:path], checkeds: checkeds).on(:change) do
                      change!
                    end
                  end
                end
              end
            end
          end

        end

        class Checkbox < HyperComponent

          param :label
          param :path
          param :checkeds
          param :show_count, default: false
          param :check_ancestors, default: false
          param :additional_paths_to_check, default: []
          param :disabled, default: false

          fires :change

          render do
            register
            DIV(class: "input-group") do
              DIV(class: "form-check") do
                INPUT(class: "form-check-input cursor-pointer", disabled: disabled.to_n, type: "checkbox", name: "column", value: path, id: input_id, checked: !!checkeds[path]) do
                end.on(:change) do |event|
                  if event.target.checked
                    checkeds[path] = true
                    if check_ancestors
                      ancestors_paths.each do |p|
                        checkeds[p] = true
                      end
                    end
                    additional_paths_to_check.each do |p|
                      checkeds[p] = true
                    end
                  else
                    if checked_descendants.any?
                      event.target.checked = false
                      next
                    else
                      checkeds.delete(path)
                    end
                  end
                  mutate_others
                  mutate
                  change!
                end
                LABEL(class: "form-check-label cursor-pointer", htmlFor: input_id) do
                  label
                end
              end
            end

            if show_count && checked_count > 0
              SPAN(class: "ml-2 badge badge-primary align-middle cursor-pointer") do
                checked_count
              end.on(:click) do
                uncheck_descendants
              end
            end
          end

          private

          def register
            a = (all_checkboxes[path] ||= [])
            a << self unless a.include?(self)
          end

          def all_checkboxes
            @@all_checkboxes ||= {}
          end

          def self.reset_all_checkboxes
            @@all_checkboxes = {}
          end

          def input_id
            @input_id ||= "check-#{rand(10000000)}"
          end

          def checked_count
            checked_descendants.length
          end

          def checked_descendants
            path_ = "#{path}."
            default_attrs = ['id', 'created_at', 'updated_at', 'deleted_at', 'type'].map{|a| ".#{a}"}
            checkeds.keys.select{|k| k.start_with?(path_) && !default_attrs.detect{|a| k.end_with?(a)} }
          end

          def mutate_others
            all_checkboxes[path]&.each do |c|
              next if c == self
              c.mutate
            end
            ancestors_paths.each do |p|
              all_checkboxes[p]&.map(&:mutate)
            end
            additional_paths_to_check.each do |p|
              all_checkboxes[p]&.each do |c|
                next if c == self
                c.mutate
              end
            end
          end

          def ancestors_paths
            return @ancestors_paths if @ancestors_paths
            prev = nil
            result = []
            path.split('.').each do |p|
              prev = prev ? "#{prev}.#{p}" : p
              result << prev if prev != path
            end
            @ancestors_paths = result
            return @ancestors_paths
          end

          def uncheck_descendants
            to_remove = checkeds.keys.select{|k| k.start_with?("#{path}.") }
            to_remove.each do |k|
              checkeds.delete(k)
            end
            to_remove.each do |k|
              all_checkboxes[k]&.map(&:mutate)
            end
            mutate
            change!
          end

          before_unmount do
            all_checkboxes[path]&.delete(self)
            @ancestors_paths = nil
          end

        end

      end
    end
  end
end
