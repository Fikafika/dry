# backtick_javascript: true

require 'components/form/element/base'
require 'components/form/element/tom_select'

class Form
  module Element
    module Association
      class Base < ::Form::Element::Base
        include Hyperstack::Router::Helpers
        include TomSelect

        after_new_params do
          init_association_min_max
        end

        render { content }

        def init_submission_params
          raise "#{self.inspect}: missing attribute_name" if attribute_name.blank?

          return super if (attribute_name.end_with?('_ids') || attribute_name.end_with?('_id')) && preloaded?
          return unless record
          return if already_initialized?

          if mode == "nested_form"
            form.submission.write_association(path, record_association_attributes)
          else
            initial_record = compute_initial_record
            if initial_record
              if initial_record.is_a?(HyperResource::Relation)
                # how to convert_value ?
                initial_record.each_with_index do |e, i|
                  form.submission.write_from_db(path + [i, 'id'], e.id)
                  form.submission.write_from_db(path + [i, 'type'], e.type) if polymorphic?
                end
              else
                form.submission.write_from_db(path, convert_value(initial_record))
              end
              form.submission.data[input_prefix] ||= {}
              form.submission.data[input_prefix][attribute_name] = initial_record
            end
          end
        end

        def preloaded?
          return true if form&.dynamic_form || record.nil?
          return record.send(association_name).present?
        end

        def already_initialized? # TODO form.submission.initialized?(self)
          if in_hash
            if form.submission.has_key?(path)
              form.submission.data.dig(input_prefix, attribute_name)
            else
              return true
            end
          elsif mode == "nested_form"
            if form.submission.has_association?(path)
              f = form.submission.read_association(path)&.[](0)
              return (!f || (f.keys != ['id'] && f.keys != ['id', 'type'])) # :( association can be already intialized in a not nested_form
            else
              return false
            end
          else
            return form.submission.has_key?(path)
          end
        end

        def compute_initial_record
          if in_hash
            if attribute_name.end_with?('_id')
              v = form.submission.read(path)
              if v
                result = (other_params[:target_relation] || target_klass).find(v) do |r|
                  update_tom_select_values if tom_select_initialized?
                end
              else
                result = other_params[:default_value]
              end
              return result
            elsif attribute_name.end_with?('_ids')

            end
          else
            result = record.send(association_name)

            if result.blank?
              if !form.dynamic_form && record.send(attribute_name_for_update).present? # *_id or *_ids present?
                form.mutate_element_after_data_loaded(self, record.association(association_name).load_target)
              else
                result = other_params[:default_value]
              end
            end

            if form.dynamic_form || !record.send(attribute_name_for_update).present?
              result = other_params[:default_value] if forced_default_value?
            end

            # on a new record, the association may come from the schema default: the form default wins
            result = other_params[:default_value] if record.new_record? && other_params[:default_value].present?
          end

          return result
        end

        def init_association_min_max
          return unless form
          form.association_min[path] = association_min if association_min
          form.association_max[path] = other_params[:max] if other_params[:max]
        end

        def association_min
          other_params[:min]
        end

        def sorting_attribute
          other_params[:sorting_attribute] || target_klass.try(:name_attribute)
        end

        def sorting_type
          other_params[:sorting_type] || :asc
        end

        def records_order
          return {sorting_attribute => sorting_type} if other_params[:sorting_attribute].present?
          default_order = default_elasticsearch_order_from_reflection
          return default_order if default_order.present?
          return {sorting_attribute => sorting_type} if sorting_attribute
        end

        def default_elasticsearch_order_from_reflection
          return unless klass.respond_to?(:reflect_on_association)
          default_order = klass.reflect_on_association(association_name).try(:default_elasticsearch_order)
          return unless default_order.is_a?(::Array)
          result = {}
          default_order.each do |pair|
            next unless pair.is_a?(::Array) && pair[0].present?
            result[pair[0]] = pair[1] || 'asc'
          end
          return result
        end

        def association_records
          target_klass_names = other_params[:target_klass_names]
          if target_klass_names.present?
            target_klass_all_records = target_klass_names&.map do |target_klass_name|
              target_klass = target_klass_name.safe_constantize
              next unless target_klass
              association_records_scope(target_klass, filters: false).all
            end
            form.mutate_element_after_data_loaded(self, target_klass_all_records)
            return target_klass_all_records.flatten
          elsif target_klass.present?
            result = association_records_scope(target_klass).all
            form.mutate_element_after_data_loaded(self, result)
            return result
          end
          return []
        end

        def association_records_scope(target_klass, filters: true)
          scope = target_klass
          if filters && autocomplete_filters_result.present? && target_klass.respond_to?(:where_filters)
            scope = scope.where_filters(autocomplete_filters_result, autocomplete_variables_proc&.call, 'UTC')
          end

          order = records_order
          if order.present?
            scope = scope.order(order)
          end
          if values_limit
            scope = scope.limit(values_limit)
          end
          return scope
        end

        def values_limit
          other_params[:values_limit]
        end

        def ordered_possible_values
          return possible_values unless other_params[:sorting_attribute]

          sorted_possible_values =  possible_values.sort_by {|possible_value| possible_value['value'].send(sorting_attribute) }
          if ['asc', 'ASC', :asc, :ASC].include?(sorting_type)
            sorted_possible_values
          elsif ['desc', 'DESC', :desc, :DESC].include?(sorting_type)
            sorted_possible_values.reverse!
          end
        end

        def render_label(possible_value_or_record)
          possible_value_or_record[:label] || possible_value_or_record[:value].try(possible_value_or_record[:value]&.class&.name_attribute) || possible_value_or_record.try(possible_value_or_record.class.name_attribute)
        end

        def possible_values_or_records
          if in_editor
            return possible_values.present? ? ordered_possible_values : association_records
          else
            @possible_values_or_records ||= possible_values.present? ? ordered_possible_values : association_records
          end
        end

        def change_data(value, record = self.record)
          value = record.send(association_name) unless value.is_a?(::HyperResource::Base) || value.is_a?(::HyperResource::Relation) # TODO find the correct way to define data
          form.submission.data[input_prefix] ||= {}
          form.submission.data[input_prefix][attribute_name] = value
        end

        def record_name(r)
          r.try(r&.class.try(:name_attribute) || 'name')
        end

        def record_photo(r)
          r.try(r&.class.try(:photo_attachment) || 'photo')
        end

        def klass
          other_params[:klass] || record&.class
        end

        def target_klass
          return other_params[:target_klass] if other_params[:target_klass]
          return other_params[:target_relation].klass if other_params[:target_relation]
          return unless klass
          return klass.reflect_on_association(association_name)&.klass
        end

        def polymorphic?
          return other_params[:polymorphic] if other_params.has_key?(:polymorphic)
          return false unless klass
          return !target_klass
        end

        def target_klass_url
          return other_params[:target_klass_url] if other_params[:target_klass_url]
          if target_klass
            if request
              params = request.params.to_h.except('_', 'rp')
            else
              params = {}
            end
            if autocomplete_filters_result.present?
              params[:filters] = Rison.dump(autocomplete_filters_result)
            end
            add_order_to_params(params)
            return target_klass.collection_path(params)
          end
          return unless record&.class&.parent&.respond_to?(:search_path)
          return record&.class&.parent.search_path(klass_names: other_params[:target_klass_names])
        end

        def target_klass_search_url
          url = target_klass_url
          return url unless url && klass && association_name && !polymorphic?
          self.class.add_params_to_url(url, owner_klass_name: klass.name, association_name: association_name)
        end

        def self.add_params_to_url(url, params)
          url = url + "?" unless url.include?('?')
          url = url + "&" unless url.end_with?('&') || url.end_with?('?')
          url += `$.param(#{params.to_n})`
          return url
        end

        def photo_tag(photo, fallback_icon)
          signed_id = photo&.attachment&.signed_id
          @photo_errors ||= {}
          if signed_id && !@photo_errors[signed_id]
            IMG({
              src: "#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/icon/icon.png",
              class: 'item-icon mr-1',
              onError: Proc.new{ @photo_errors[signed_id] = true; mutate }
            })
          else
            SPAN(class: 'item-icon mr-1') do
              I(class: "fas fa-#{fallback_icon} fa-inverse"){}
            end
          end
        end

        def self.tom_select_item_template(text, signed_id, fallback_icon)
          if signed_id
            photo = %Q[
              <img src="#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/icon/icon.png" class="item-icon mr-1" onerror="$(this).addClass('d-none'); $(this).next().removeClass('d-none')"/>
            ]
          end
          text = "" unless text
          result = %Q[
            #{photo}
            <span class="item-icon #{signed_id ? 'd-none' : nil} mr-1">
              <i class="fas fa-#{fallback_icon} fa-inverse"></i>
            </span>
            #{text}
          ].gsub(/^\n/, '').gsub(/\>\n\s*/, '>') # prevent additional spaces
          return result
        end

        def polymorphic_new(attrs)
          a = (target_klass || attrs['type']&.safe_constantize)
          return a&.polymorphic_new_and_keep_initial_json(attrs)
        end

        def displayed_label
          # redefined because there is no translation when attribute_name ends with _id
          return label || (other_params[:label_attribute] && record&.send(other_params[:label_attribute])) || record_klass&.human_attribute_name(association_name)&.capitalize
        end

        # input ------------------------------------------------------------------

        def render_input
          try("render_input_#{editor || 'select'}")
        end

        def render_input_select  # editor == 'select'
          layout_input do
            SELECT(select_args) do
              select_options
            end
            input_errors
          end
        end

        def select_args
          result = {
            id: input_id,
            name: input_name,
            class: "form-control #{invalid_css_class}",
            style: {
              width: '100%'
            }
          }
          result[:style][:display] = 'none' if use_tom_select? && tom_select_initialized?
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readOnly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        def select_options
          selected_values.each do |pv|
            OPTION(value: pv[:value]) do
              pv[:label]
            end
          end
        end

        def self.item_icon(item)
          return unless `item.record` && `item.record.type`
          return `item.record.type`.safe_constantize.try(:icon)
        end

        def init_tom_select_events
          if in_editor && mode == 'nested_form'
            ::Element.find("[data-element-id='#{other_params[:id]}'] .ts-wrapper").remove
          else
            super
          end
        end

        def tom_select_options # redefined
          self.class.tom_select_options(target_klass, target_klass_search_url, invalid_css_class, autocomplete_variables_proc, cache_items_proc)
        end

        def self.tom_select_options(target_klass, target_klass_url, css_class = nil, autocomplete_variables_proc = nil, cache_items_proc = nil)
          first_url_proc = Proc.new do |query|
            @tom_select_page = 1
            params = {term: query, select2: true}
            variables = autocomplete_variables_proc&.call
            params[:variables] = variables.to_n if variables&.any?
            url = add_params_to_url(target_klass_url, params)
            url
          end
          return {
            valueField: 'id',
            allowEmptyOption: true,
            loadThrottle: 100, # faster than default 300
            onFocus: Proc.new do
              `this.load()`
            end,
            plugins: ['virtual_scroll'],
            shouldLoad: Proc.new { |query| true }, # fix bug when clear input using backspace
            firstUrl: first_url_proc,
            load: Proc.new  do |query, callback|
              dropdown = `this`
              @ajax&.abort
              url = `this.getUrl(#{query})`
              set_next_url = `this.setNextUrl`
              unless url
                url = first_url_proc.call(query)
              end
              @ajax = HttpWithCrossDomain.get(url) do |response|
                if response.ok?
                  json = `#{response.xhr}.responseJSON || JSON.parse(#{response.xhr}.responseText)`
                  items = `json['results']`

                  cache_items_proc&.call(items)

                  if `json['pagination'] && json['pagination']['more']`
                    @tom_select_page += 1
                    if url.include?('page=')
                      url = url.gsub(/page\=(\d+)/, "page=#{@tom_select_page.to_s}")
                    else
                      url = add_params_to_url(url, page: @tom_select_page)
                    end
                    set_next_url.call(query, url)
                  end

                  prevent_tom_select_scroll(dropdown, query, @tom_select_page) do
                    `callback(#{items})`
                  end
                else
                  `callback()`
                end
              end
            end,
            render: {
              option: `function(item, escape) {
                const fallback_icon = #{target_klass.try(:icon) || `#{self.method(:item_icon)}.method(item)`}
                return '<div>' + #{self.method(:tom_select_item_template)}.method(item.text, item.photo_id, fallback_icon) + '</div>'
              }`,
              option_create: `function(data, escape){
                return '<div class="create">' + I18n.t('shared.add') + ' ' + escape(data.input) + '</div>'
              }`,
              no_results: `function(data, escape){
                return '<div class="no-results">' + I18n.t('shared.none') + '</div>'
              }`,
              loading: `function(data, escape){
                return '<div class="ml-2 fa fa-spinner fa-pulse"></div>'
              }`,
              loading_more: `function(data, escape){
                return '<div class="loading-more-results">' + I18n.t('shared.loading_more') + '</div>'
              }`,
              no_more_results: `function(data, escape){
                return '<div class="no-more-results">' + I18n.t('shared.no_more_results') + '</div>'
              }`,
            }
          }
        end

        def update_disabled_to_tom_select # redefined
          if disabled_by_autocomplete || disabled
            `#{@tom_select}.disable()`
          else
            `#{@tom_select}.enable()`
          end
        end

        def tom_select_disabled_changed?
          return false unless tom_select_initialized?
          result = (disabled_by_autocomplete || disabled) != @previous_disabled
          @previous_disabled = disabled_by_autocomplete || disabled
          return result
        end

        def self.prevent_tom_select_scroll(dropdown, query, page) # fix a bug when query is not empty and scroll
          if query.present? && page && page > 2
            %x{
              const _scrollToOption = dropdown.scrollToOption
              dropdown.scrollToOption = () => {}
            }
            yield
            `dropdown.scrollToOption = _scrollToOption`
          else
            yield
          end
        end

        def cache_items(items)
          return unless `Array.isArray(items)`
          Array(items).each do |i|
            items_cache[`i.id`] = i
          end
        end

        def cache_items_proc
          @cache_items_proc ||= Proc.new { |items| cache_items(items) }
        end

        def items_cache
          @items_cache ||= {}
        end

        def autocomplete_filters_result
          return @autocomplete_filters_result_with_default if @autocomplete_filters_result_with_default_computed
          result = super
          result = default_elasticsearch_filters_from_reflection if result.blank?
          @autocomplete_filters_result_with_default_computed = !!klass
          @autocomplete_filters_result_with_default = result
          return result
        end

        def default_elasticsearch_filters_from_reflection
          return unless klass.respond_to?(:reflect_on_association)
          klass.reflect_on_association(association_name).try(:default_elasticsearch_filters)
        end

        def determine_autocomplete_variable_values
          @variables ||= extract_variables(autocomplete_filters_result)
          return unless @variables.any?

          result = {}
          @variables.each do |v|
            path = add_nums(form.prefix_path + v.split('.'))

            value = form.submission.read(path)

            if value.is_a?(Array) && value.first.is_a?(Hash) && value.first.has_key?('id')
              value = value.map{|h| h['id']}
            elsif value.is_a?(Hash) && value.has_key?('id')
              # For polymorphic associations
              value = value['id']
            end

            if value.nil? && form.dynamic_form
              reflection = form.dynamic_form.association_reflection
              if reflection && v == reflection.options[:inverse_of]
                value = form.other_params[:target_record_id]
              end
            end

            if other_params[:convert_autocomplete_variable]
              value = other_params[:convert_autocomplete_variable].call(v, value)
            end

            result[v] = value
          end
          return result
        end

        def add_nums(path_without_nums) # not sure about this part
          result = []
          j = 0

          l = path_without_nums.length * 2 - 1
          self.path.each_with_index do |p, i|
            break if i >= l
            if p == path_without_nums[j]
              result << p
              j += 1
            elsif p.is_a?(Integer)
              result << p
            else
              t = path_without_nums[j]
              result << t if t
              j += 1
            end
          end
          while j < path_without_nums.length
            result << path_without_nums[j]
            j += 1
          end

          return result
        end

        def self.template_result_ruby(target_klass)
          return Proc.new do |item|
            fallback_icon = target_klass.try(:icon) || item_icon_ruby(item)
            next tom_select_item_template(item[:text], item[:photo_id], fallback_icon)
          end
        end

        def self.item_icon_ruby(item)
          t = item.dig(:record, :type)
          return unless t
          return t.safe_constantize.try(:icon)
        end

        def value_from_tom_select_data # redefined
          current_items = `#{select_element.to_n}[0].tomselect.items`
          @tom_select_record_cache ||= {}
          current_items.each do |id|
            d = items_cache[id]
            r = `#{d}.record`
            next unless r
            attrs = ::Hash.new(r)
            @tom_select_record_cache[id] ||= polymorphic_new(attrs)
          end
          return current_items.map{|id| @tom_select_record_cache[id] || record_from_submission_data(id) }
        end

        def record_from_submission_data(id)
          form&.submission&.data&.dig(input_prefix, attribute_name)&.detect{|e| e.id == id }
        end

        def use_tom_select?
          [nil, 'select', 'select2', 'tom_select'].include?(editor) && [nil, 'input'].include?(mode)
        end

        def render_input_select2 # keep compatibility when editor == 'select2'
          render_input_select
        end

        def render_input_hidden
          unless in_editor
            values = selected_values
            if values.any?
              values.each do |v|
                INPUT(select_args.merge(type: 'hidden', defaultValue: v[:value]))
              end
            else
              INPUT(select_args.merge(type: 'hidden'))
            end
          else
            layout_input_hidden do
            end
          end
        end

        # edit in place --------------------------------------------------------

        def render_edit_in_place
          layout_edit_in_place do
            if edit_in_place_editing?
              render_edit_in_place_editing
            else
              render_edit_in_place_not_editing
            end
          end
        end

        def render_edit_in_place_not_editing
        end

        def render_edit_in_place_editing
        end

        def edit_in_place_submit_value(value)
          if @original_value != value
            if requirement == 'mandatory' && value.blank?
              @success = false
              change_value(@original_value)
              error = {error: :blank}
              form.error!(error)
            else
              @loading = true
              @success = nil
              around_edit_in_place_submit_value do
                record.update(edit_in_place_params_for_update(value), @edit_in_place_submit_options).then do |response|
                  @success = response[:success]
                  @loading = false
                  if @success
                    record.association(association_name).target = value
                    change_value(value)
                  end
                  @success ? form.success!(response, form) : form.error!(response, form)
                  mutate
                  yield(response) if block_given?
                end
              end
            end
          end
          @edit = false
          mutate
        end

        def attribute_name_for_update
          attribute_name
        end

        def edit_in_place_params_for_update(value)
          { attribute_name_for_update => convert_value_to_id(value) }
        end

        def edit_in_place_input_id
          "edit_in_place_#{input_id}"
        end

        def selected_record(value)
          result = nil
          if value
            attrs = value['record']
            if attrs
              result = polymorphic_new(attrs)
            else
              result = form.submission.data.dig(input_prefix, attribute_name) # still needed ?
            end
          end
          return result
        end

        def render_item(e, options = {})
          item_link(e, options) do
            photo_tag(record_photo(e), e.class.try(:icon))
            record_name(e)
          end
        end

        def item_link(e, options = {})
          unless browsable?
            SPAN(options) do
              yield
            end
          else
            Link(url_for(record: e, action: 'edit'), options.merge('data-open-panel' => 'opposite')) do
              yield
            end.on(:click) do |event|
              event.stop_propagation
            end.on(:mouse_enter) do |event|
              @mouse_hover_link = true
              mutate
            end.on(:mouse_leave) do |event|
              @mouse_hover_link = false
              mutate
            end
          end
        end

        def browsable?
          (mode == 'edit_in_place' || mode == 'read_only') && form&.other_params[:render_edit_record_links] != false
        end

        # nested form -------------------------------------------------------------

        def render_nested_form
          try("render_nested_form_#{editor || 'input'}")
        end

        def render_nested_form_input
          return render_nested_form_input_in_editor if in_editor
          layout_nested_form_input do
            values = values_for_nested_form
            count = values.select{|e| !e['_destroy']}.length
            values.each_with_index do |v, i|
              layout_nested_form_item(v, i, count) do
                i_ = orderable_association? ? form.submission.read_association(path).index(v) : i
                prefix_path = self.path + [i_]
                next if v['_destroy']

                record = nested_form_record(v, prefix_path)

                next unless record

                if show_item_header?
                  args = {form: form, record: record, prefix_path: prefix_path, index: i, min: other_params[:min], embeded: true, position: v[:position]}
                  ::Form::Element::Control::ItemHeader.create_element(args).render(args)
                elsif show_item_separator?
                  if i == 0
                    item_top_padding
                  else
                    item_separator
                  end
                end

                layout_nested_form_item_padding do
                  other_params[:element_children]&.each do |e|
                    form.render_child(form.convert_dynamic_form_element(e), prefix_path, record, conditions, in_hash)
                  end
                  children.each do |c|
                    form&.render_child(c, prefix_path, record, conditions, in_hash)
                  end
                end
              end
            end
          end
        end

        def nested_form_record(v, prefix_path)
          use_cache = v && v['id'] && form&.mode == 'edit_in_place' # what to do with other modes ?

          if use_cache
            @nested_form_values_record_cache ||= {}
            record = @nested_form_values_record_cache[v['id']]
          end

          if record.nil?
            record = polymorphic_new(v)

            return if record.nil?

            if use_cache
              @nested_form_values_record_cache[v['id']] = record
            end
          end

          errors = form.submission.nested_errors(prefix_path)
          if errors || record.errors
            record.errors = errors || {}
          end

          return record
        end

        def render_nested_form_hidden
          return render_nested_form_input_in_editor if in_editor

          DIV(class: 'd-none') do
            values = values_for_nested_form

            values.each_with_index do |v, i|
              i_ = orderable_association? ? form.submission.read_association(path).index(v) : i
              prefix_path = self.path + [i_]
              next if v['_destroy']

              record = nested_form_record(v, prefix_path)

              next unless record

              other_params[:element_children]&.each do |e|
                form.render_child(form.convert_dynamic_form_element(e), prefix_path, record, conditions, in_hash)
              end
              children.each do |c|
                form&.render_child(c, prefix_path, record, conditions, in_hash)
              end
            end
          end
        end

        def layout_nested_form_item(value, index, count)
          yield
        end

        def layout_nested_form_item_padding
          if show_label
            DIV(class: 'pl-2 pr-2') do
              yield
            end
          else
            yield
          end
        end

        def show_item_header?
          return false if disabled_by_autocomplete || disabled || readonly
          !!(other_params.has_key?(:show_item_header) ? other_params[:show_item_header] : true)
        end

        def show_item_separator?
          !!(other_params.has_key?(:show_item_separator) ? other_params[:show_item_separator] : true)
        end

        def item_separator
          DIV(class: 'border-bottom w-100 mb-3') do
          end
        end

        def item_top_padding
          DIV(class: 'mb-3'){}
        end

        def layout_nested_form_input
          DIV(ref: _ref, class: "row") do
            DIV(class: 'col') do
              if show_label
                DIV(class: 'row') do
                  DIV(class: "col", htmlFor: input_id) do
                    displayed_label
                  end
                end
              end
              DIV(class: "row") do
                DIV(class: 'col') do
                  if help.present?
                    SPAN(id: "help-#{form_group_id}", class: "help-block", dangerously_set_inner_HTML: { __html: help }) do
                    end
                  end
                  yield
                end
              end
            end
          end
        end

        def records_for_nested_form
          return []
        end

        def attrs_for_new_record
          return other_params[:attrs_for_new_record] if other_params[:attrs_for_new_record]

          return @attrs_for_new_record if @attrs_for_new_record

          result = {}
          children.each do |c|
            next unless c.props[:default_value]
            result[c.props[:attribute_name]] = c.props[:default_value]
          end

          @attrs_for_new_record = result
          return result
        end

        def render_nested_form_input_in_editor
          DIV(ref: _ref, class: "row mb-1") do
            DIV(class: 'col') do
              if show_label && editor != 'hidden'
                DIV(class: 'row') do
                  DIV(class: "col") do
                    displayed_label
                  end
                end
              else
                DIV(class: 'row') do
                  DIV(class: "col", style: {opacity: 0.5}) do
                    displayed_label
                  end
                end
              end
              DIV(class: "row") do
                DIV(class: 'col') do
                  if help.present?
                    SPAN(id: "help-#{form_group_id}", class: "help-block", dangerously_set_inner_HTML: { __html: help }) do
                    end
                  end
                  children.render
                end
              end
            end
            if children.length == 0
              DIV(class: 'form-editor-dropzone') do
              end
            end
          end
        end

        def record_attributes(record, children_elements = self.children)
          return unless record

          if record._initial_json
            result = record._initial_json || {} # need dup ?
            record.class.globalize_accessor_names.each do |n| # TODO check if needed
              result[n] = record.send(n)
            end
            # should be dup and remove associations not used in children ?
            return result.dup
          else
            result = record.attributes.dup
            record.class.globalize_accessor_names.each do |n|
              result[n] = record.send(n)
            end
            for_each_child(children_elements) do |attr_name, sub_children|
              a = record.class.reflect_on_association(attr_name)
              case a
              when HyperResource::Reflection::HasManyReflection
                result[a.name] = record.send(a.name)&.map { |r| record_attributes(r, sub_children) } || []
              when HyperResource::Reflection::BelongsToReflection
                result[a.name] = record_attributes(record.send(a.name), sub_children)
              end
            end
            return result
          end
        end

        def for_each_child(children, &block)
          # some children elements have a nil attribute_name because they are condition wrappers but they contain nested children that do have attribute_names so we need to recurse into them to find all the attributes names
          children&.each do |c|
            attr_name = c.props["attribute_name"]
            if attr_name.present?
              sub = c.props["children"]
              sub = [sub] if sub && !sub.is_a?(Array)
              yield attr_name, sub
            else
              nested = c.props["children"]
              next unless nested
              nested = [nested] unless nested.is_a?(Array)
              for_each_child(nested, &block)
            end
          end
        end

        def orderable_association?
          false
        end

        def values_for_nested_form
          values = form.submission.read_association(path) || []

          if condition_formula
            values = values.select do |v|
              condition_evaluator.run_eval(Proc.new {|path| v[path] })
            end
          end

          if values.any? && orderable_association?
            values = values.sort_by{|v| v[:position] || 0 }
          end
          return values
        end

        def condition_evaluator
          @condition_evaluator ||= ::Dynamic::Form::Element::Layout::Condition::Evaluator.new(condition_formula)
        end

        # edit cell ----------------------------------------------

        def render_edit_cell
          render_edit_in_place_editing
        end

        track_changes [:other_params, :target_klass_url]

        def must_destroy_tom_select?
          return true if other_params_target_klass_url_changed?
          return false unless @previous_record_id
          return (@previous_record_id != record&.id)
        end

      end
    end
  end
end
