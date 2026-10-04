# backtick_javascript: true

class Form
  class Editor < HyperComponent

    param :schema_id, default: nil
    param :klass_id, default: nil
    param :form_id, default: nil

    attr_accessor :is_saving

    collect_other_params_as :other_params

    render do
      observe form if form

      if serialized_schema && serialized_form
        DIV(class: 'w-100 h-100') do
          FormEditor(
            formName: form.human_name.to_s,
            leftPanel: left_panel.to_n, # menu items
            centerPanel: serialized_form.to_n, # form to be managed
            returnBackButton: { # return back button's params (at top Toolbar)
              callBack: return_back_button_on_click
            }.to_n,
            previewButton: build_preview_button_hash,
            saveButtonOnClick: save_button_on_click, # save button's onClick handler (at bottom Toolbar)
            getComponentClass: get_component_class, # element's Component class (e.g., LayoutRow, LayoutColumn, AttributeString)
            getPanelClass: get_panel_class, # left panel component
            createElementFromLeftPanel: create_element_from_left_panel,
            convertElementAttributesToComponentProps: convert_element_attributes_to_component_props
          )
        end
      end
    end

    def build_preview_button_hash
      {
        url: "/crm/#{schema_id}/forms/#{form.id}",
        label: I18n.t('settings.schema.forms.goto_form')
      }.to_n
    end

    def left_panel
      @left_panel ||= {
        components: components,
        schema: serialized_schema,
        klassId: klass_id.to_s.camelize,
      }
    end

    def components
      result = [{
        human_name: ::Dynamic::Form::Element::Basic::Base.model_name.human(count: 2),
        children: component_klasses.map do |k|
          type = k.name.gsub(/^Dynamic::Form::Element::/, '')
          {
            human_name: k.model_name.human, #I18n.t("#{e}/#{type.underscore}"),
            klass_name: form.klass_name,
            type: type,
          }
        end + [{
          human_name: Dynamic::Form::Element::Layout::AdditionalFieldsContainer.model_name.human,
          type: 'Layout::AdditionalFieldsContainer',
        }]
      }]
      return result
    end

    def component_klasses
      result = [
        ::Dynamic::Form::Element::Basic::Text,
        ::Dynamic::Form::Element::Layout::Condition,
      ]
      case form.mode
      when 'input'
        result.concat([
          ::Dynamic::Form::Element::Layout::Page,
          ::Dynamic::Form::Element::Layout::Section,
          ::Dynamic::Form::Element::Control::Navigation,
          ::Dynamic::Form::Element::Control::AddButton,
        ])
      when 'edit_in_place'
        result.concat([
          ::Dynamic::Form::Element::Layout::Section,
          ::Dynamic::Form::Element::Control::AddButton,
        ])
      end
      return result
    end

    def schema
      return other_params[:schema] if other_params[:schema]

      @schema ||= ::Dynamic::Schema.includes(self.class.as_deep_json_options_for_schema[:include]).find(schema_id) { mutate }
    end

    def serialized_schema
      return @serialized_schema if @serialized_schema
      if schema&.loaded?
        @serialized_schema = schema.as_deep_json(self.class.as_deep_json_options_for_schema)
        add_inherited_attrs_assocs_and_attachments(@serialized_schema)
      end
      return @serialized_schema
    end

    def self.as_deep_json_options_for_schema
      {
        include: {
          klasses: {
            include: {
              attrs: 1,
              associations: 1,
              attachments: 1,
            },
            except: [
              'elasticsearch_mapping',
              'elasticsearch_updated_at',
              'options_for_indexed_json',
              'dependencies_from_formulas',
            ]
          }
        },
        secure: false,
      }
    end

    def add_inherited_attrs_assocs_and_attachments(serialized_schema)
      return unless serialized_schema['klasses']
      klasses_by_id = {}
      serialized_schema['klasses'].each{|k| klasses_by_id[k['id']] = k}
      serialized_schema[:klasses].sort_by{|k| k['id']}.each do |k|
        s_id = k['superklass_id']
        next unless s_id.present? && s = klasses_by_id[s_id]
        ['attrs', 'associations', 'attachments'].each do |a|
          k[a] =  (s[a] || []).concat(k[a] || [])
        end
      end
    end

    def form
      return other_params[:form] if other_params[:form]
      @form ||= ::Dynamic::Form.includes(
        self.class.as_deep_json_options_for_form[:include]
      ).where(
        schema_id: schema_id,
        klass_id: klass_id,
      ).find(form_id)
    end

    def serialized_form(reload = false)
      return @serialized_form if @serialized_form && !reload
      if form&.loaded?
        @serialized_form = form.as_deep_json(self.class.as_deep_json_options_for_form)
      end
      return @serialized_form
    end

    def self.as_deep_json_options_for_form
      return {
        include: {
          elements: {
            include: {
              parent_id: 1,
              possible_values: {
                include: {
                  translations: 1,
                  value_record: 1,
                }
              },
              default_value_record: 1,
              default_value_records: 1,
              translations: 1,
              attachments: { # TODO should be simpler
                include: {
                  attachments: {
                    include: {
                      signed_id: 1,
                      filename: 1,
                    }
                  }
                }
              },
            },
          }
        },
        secure: false,
      }
    end

    def return_back_button_on_click
      return other_params[:return_back_button_on_click] if other_params[:return_back_button_on_click]
      return Proc.new do
        puts "callback not provided"
      end
    end

    def save_button_on_click
      return Proc.new do |params|
        params = clean_form_params(params)

        @promise = Promise.new
        if is_saving
          @promise.resolve({ error: "Save  in progress" }.to_n)
          next @promise.to_n
        end
        self.is_saving = true
        form.update(params).then do |response|
          self.is_saving = false
          if response[:success]
            @serialized_form = nil
            form.reload do
              @promise.resolve({ success: true, form: serialized_form(true)}.to_n)
            end
          else
            @promise.resolve(response.to_n)
          end
        end.fail do
          # TODO
        end

        @promise.to_n
      end
    end

    def clean_form_params(params)
      #TODO:
      result = JSON.parse(`JSON.stringify(#{params})`) # too many conversions :( use jquery directly
      result['elements']&.each do |e|
        if e['possible_values_attributes']
          e.delete('possible_values')
        elsif e['possible_values']
          e['possible_values_attributes'] = e.delete('possible_values')
        end
        e['possible_values_attributes']&.each do |e2|
          if e2['value_record']
            e2['value_record_type'] = e2['value_record']['type']
            e2['value_record_id'] = e2['value_record']['id']
          end
          e2.delete('value_record')
          e2.delete('value_record_attributes')
          e2.delete('translations')
        end

        if e['type'] == 'Basic::Text' && e['attachments']
          e['attachments'] = e['attachments']['attachments'].map{|a| a['signed_id'] } # why active_storage is so hard ? :(
        else
          e.delete('attachments') # why other types have image attribute ?
        end
        e.delete('translations')
        if e['default_value_record']
          e.delete('default_value')
          e['default_value_record_type'] = e['default_value_record']['type']
          e['default_value_record_id'] = e['default_value_record']['id']
        end
        e.delete('default_value_record')
        e.delete('default_value_record_attributes')
        e.delete('default_value_records')
        e.delete('default_value') if e['default_value'].is_a?(Array)
        e['parent_id'] ||= nil # when an element have moved from a parent to root. uneek_form_editor node_module should not remove parent_id key
      end
      result['elements_attributes'] = result.delete('elements') if result['elements']
      # should when assign to a form and serialize this form ?

      return result
    end

    def get_component_class
      return Proc.new do |class_name|
        Hyperstack::Internal::Component::ReactWrapper.create_native_react_class(('Form::Element::' + class_name).safe_constantize)
      end
    end

    def convert_element_attributes_to_component_props
      return Proc.new do |attrs, tree|
        e = ::Dynamic::Form::Element::Base.polymorphic_new(Hash.new(attrs))
        result = convert_dynamic_form_element_attributes(e, tree)
        r = result.except(:css_classes).to_n #NOTE: this replace HyperResource instances with id by nil
        # Reaffecting possible values as record because it was replaced by nil:
        if result[:possible_values]
          result[:possible_values].each_with_index do |p, i|
            if p[:value]
              `#{r}['possible_values'][#{i}]['value'] = #{p[:value]}`
            end
          end
        end
        if result[:default_value_record]
          `#{r}['default_value_record'] = #{result[:default_value_record]}`
        end
        `#{r}['css_classes'] = #{result[:css_classes]}` if result[:css_classes]
        r
      end
    end

    def convert_dynamic_form_element_attributes(element, tree)
      result = ::Form.convert_dynamic_form_element_attributes(element)
      @fake_form ||= FakeForm.new(form, tree)
      result[:form] = @fake_form
      result[:in_editor] = true
      result[:klass_name] = element.klass_name
      result[:record] = element.klass_name&.safe_constantize&.new if ['read_only', 'diff', 'edit_in_place'].include?(form.mode)
      result[:same_as_id] = element.same_as_id
      if element.klass_name
        result[:prefix_path] = element_prefix_path(element)
        @fake_form.init_default_value(element, result[:prefix_path] + [element.attribute_name])
      end
      return result
    end

    def element_prefix_path(element)
      [element.klass_name.demodulize.underscore] + (element.method_names || []).map{|m| [m, 0]}.flatten
    end

    def get_panel_class
      return Proc.new do |element|
        component = self.class::Panel::Empty
        if element
          element = Hash.new(element)
          panel_klass = "#{self.class.name}::Panel::#{element['type']}".safe_constantize
          unless panel_klass
            n = element['type'].to_s.split('::')
            n.pop
            panel_klass = "#{self.class.name}::Panel::#{n.join('::')}::Base".safe_constantize
          end
          component = panel_klass if panel_klass
        end
        Hyperstack::Internal::Component::ReactWrapper.create_native_react_class(component)
      end
    end

    def create_element_from_left_panel
      return Proc.new do |dropped, path|
        dropped = ::Hash.new(dropped)
        result = {
          type: dropped[:type],
          attribute_name: dropped[:name],
          requirement: 'optional',
        }

        if dropped[:klass_id] || dropped[:owner_klass_id]
          klass_id = dropped[:klass_id] || dropped[:owner_klass_id]
          schema_klass = schema.klasses.detect{|k| k.id == klass_id }
          result[:klass_name] = schema_klass&.const_absolute_name
        end

        if path
          root_name, *method_names = path

          result[:method_names] = method_names
          if root_name && result[:klass_name]
            # compute absolute root klass name
            a = result[:klass_name].split('::')
            a.pop
            a.concat([root_name])
            result[:root_klass_name] = a.join('::')
          end
        end

        result[:klass_name] ||= dropped[:klass_name] if dropped[:klass_name]
        result[:root_klass_name] ||= result[:klass_name]

        # TODO find a better way to initialize default values in form
        default_values = "Form::Element::#{dropped[:type]}".safe_constantize.try(:default_values)
        result.merge!(default_values) if default_values.is_a?(::Hash)

        result.to_n
      end
    end

  end
end
