# backtick_javascript: true

class Form
  class Integrator < HyperComponent

    param :schema_id, default: nil
    param :klass_id, default: nil
    param :form_id, default: nil

    attr_accessor :is_saving

    collect_other_params_as :other_params

    before_unmount do
      ::Form::Integrator::Store.reset
    end

    render do
      observe form if form
      observe schema if schema
      if serialized_schema && serialized_form
        DIV(class: 'w-100 h-100') do
          FormEditor(
            formName: form.human_name.to_s,
            leftPanel: left_panel.to_n,
            centerPanel: serialized_form.to_n,
            returnBackButton: {
              callBack: return_back_button_on_click
            }.to_n,
            saveButtonOnClick: save_button_on_click,
            getComponentClass: get_component_class,
            getPanelClass: get_panel_class,
            convertElementAttributesToComponentProps: convert_element_attributes_to_component_props
          )
        end
      end
    end

    def left_panel
      @left_panel ||= {
        components: '',
        schema: '',
        klassId: '',
      }
    end

    def schema
      return other_params[:schema] if other_params[:schema]
      @schema ||= ::Dynamic::Schema.includes(self.class.as_deep_json_options_for_schema[:include]).find(schema_id)
      @schema
    end

    def serialized_schema
      return @serialized_schema if @serialized_schema
      current_schema = self.schema
      if current_schema
        @serialized_schema = schema.as_deep_json(self.class.as_deep_json_options_for_schema)
      else
        @serialized_schema = nil
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
            }
          }
        },
        secure: false,
      }
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
          klasses: {
            include: {
              attrs: 1,
              associations: 1,
              attachments: 1,
            }
          },
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
              attachments: {
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
      result = JSON.parse(`JSON.stringify(#{params})`)
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
          e['attachments'] = e['attachments']['attachments'].map{|a| a['signed_id'] }
        else
          e.delete('attachments')
        end
        e.delete('translations')
        if e['default_value_record']
          e['default_value_record_type'] = e['default_value_record']['type']
          e['default_value_record_id'] = e['default_value_record']['id']
        end
        e.delete('default_value_record')
        e.delete('default_value_record_attributes')
        e.delete('default_value_records')
        e.delete('default_value') if e['default_value'].is_a?(Array)
        e['parent_id'] ||= nil
      end
      result['elements_attributes'] = result.delete('elements') if result['elements']

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
        r = result.to_n
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
      if schema&.loaded?
        base_class = klass_id.to_s.camelize
        base_class_name = if base_class
          "#{schema.const.name}::#{base_class}"
        else
          nil
        end
        Panel::Base.current_schema_info = {
          schema_id: schema_id,
          base_class: base_class_name,
          permalink: schema.name,
          form_id: form_id,
          target_klass_name: form.target_klass_name
        }
      end
      return Proc.new do |element|
        component = "#{self.class.name}::Panel::Empty".safe_constantize
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
        Hyperstack::Internal::Component::ReactWrapper.create_native_react_class(component, props)
      end
    end

  end
end