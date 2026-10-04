module Permission
  class Form < ::Form

    TRANSLATION_KEY_BY_OPERATION = {
      '==' => 'equal',
      '!=' => 'not_equal',
      '>' => 'greater',
      '<' => 'lesser',
      '<=' => 'greater_equal',
      '>=' => 'lesser_equal',
      'start_with?' => 'starts_with',
      'end_with?' => 'ends_with',
      'include?' => 'contains',
      'exclude?' => 'not_contains'
    }.freeze

    RECEIVER_KLASSES = [
      'User',
      'Role',
      'UneekPermission::PredefinedReceiver::Base'
    ].freeze

    param :rule
    param :editable, :default => false
    param :on_instance
    param :receiver
    param :possible_attributes_values, default: []

    collect_other_params_as :other_params

    fires :delete
    fires :edit

    before_mount do
      init_value
    end

    before_new_params do |new_params_hash|
      mutate @errors = @errors.merge(new_params_hash[:errors]) unless new_params_hash[:errors].blank?
    end

    def init_value
      @value = {
        id: rule.id,
        receiver: receiver,
        permission: rule.permission.gsub('_', '').split(''),
        condition: {
          attr: rule.domain&.dig(:instance_field),
          operation: rule.domain&.dig(:expression_method),
          value: rule.domain&.dig(:expression_value),
          target: target_from_domain,
          context_field: rule.domain&.dig(:context_field),
          user_field: rule.domain&.dig(:user_field)
        }
      }
    end

    def target_from_domain
      if rule.domain&.dig(:context_field)
        'domain'
      elsif rule.domain&.dig(:user_field)
        'user'
      else
        'value'
      end
    end

    render { content }

    def content
      DIV(class: 'list-group-item') do
        if can_edit_rule?
          display_edit_buttons
        end

        if is_rule_global? && rule.klass_name.demodulize != 'DynamicRecord'
          DIV() do
            rule_klass = rule.klass_name.safe_constantize
            I18n.t('permission.comes_from', source: rule_klass.model_name.human + (rule.attr.present? ? ".#{rule.attr}" : ''))
          end
        end

        display_mandatory_fields

        if should_display_domain_management?
          display_domain_management
        end

        if @errors&.dig(:server_error)
          show_errors
        end

        if editable
          display_footer
        end
      end
    end

    def display_mandatory_fields
      ::Form::Element::Association::BelongsTo(
        record: rule,
        form: self,
        label: I18n.t('permission.receiver'),
        value: @value[:receiver],
        prefix_path: [rule.id],
        attribute_name: 'receiver',
        target_klass_url: search_path(klass_names: RECEIVER_KLASSES),
        disabled: !editable,
        requirement: 'mandatory',
        valid: !@errors&.dig(:receiver)
      ).on(:change) do |v, f, e|
        @errors.delete(:receiver) if @errors&.dig(:receiver)
        mutate @value[:receiver] = v
      end

      ::Form::Element::Attribute::MultipleEnum(
        record: rule,
        form: self,
        label: I18n.t('permission.permissions'),
        type: 'checkbox',
        prefix_path: [rule.id],
        attribute_name: 'permissions',
        value: @value[:permission],
        disabled: !editable,
        requirement: 'optional'
      ).on(:change)  do |v, f, e|
        mutate @value[:permission] = v
      end
    end

    def search_path(parameters = {})
      ::HyperResource::Base.interpolate_path_and_add_parameters("#{ENV['APP_PATH_PREFIX']}/api/search", parameters)
    end

    def display_edit_buttons
      DIV(class: 'mr-0', style: {marginLeft: 'auto', width: 'fit-content'}) do
        BUTTON(class: 'btn btn-link text-dark-yiq text-hover-secondary', title: I18n.t('shared.edit')) do
          I(class: 'fas fa-pencil-alt')
        end.on(:click) do
          edit!(rule)
        end
        BUTTON(class: 'btn btn-link text-dark-yiq text-hover-danger', title: I18n.t('shared.delete')) do
          I(class: 'fa fa-trash-alt')
        end.on(:click) do
          delete!(rule)
        end
      end
    end

    def can_edit_rule?
      return false if rule.receiver.is_a?(Role) && rule.receiver.admin
      return false if is_rule_global?
      return !rule.new_record?
    end

    def is_rule_global?
      return on_instance && rule.instance_id.nil? && rule.klass_name.safe_constantize
    end

    def should_display_domain_management?
      return possible_attributes_values.any? && (editable || rule.domain)
    end

    def display_domain_management
      DIV(class: 'row form-group') do
        LABEL(class: 'col-md-3 control-label') do
          I18n.t('permission.condition')
        end
        DIV(class: 'col-md-9 input-group') do
          Form::Element::Attribute::SerializedArray(
            style: {minWidth: '33%'},
            record: rule,
            form: self,
            value: @value.dig(:condition, :attr),
            prefix_path: [rule.id],
            attribute_name: 'contidion[attr]',
            accept_empty_value: true,
            placeholder: 'attr',
            possible_values: possible_attributes_values,
            requirement: 'mandatory',
            selectable_expandable_option: false,
            show_label: false,
            disabled: !editable
          ).on(:change) do |attr|
            @value[:condition][:attr] = attr.empty? ? nil : attr
            @value[:condition][:operation] = nil
            @value[:condition][:value] = nil
            @value[:condition][:context_field] = nil
            mutate
          end

          if @value.dig(:condition, :attr)
            display_attr_selector
          end

          if @value.dig(:condition, :attr) && @value.dig(:condition, :target)
            display_operator_selector
          end

          if @value.dig(:condition, :operation)
            attribute_type = attr_type(@value.dig(:condition, :attr))
            value_editor(attribute_type, @value.dig(:condition, :target))
          end
        end
      end
    end

    def display_attr_selector
      SELECT(
        class: html_classes_for_value_editor(@errors&.dig(:condition, :target)),
        value: @value[:condition][:target],
        disabled: !editable,
        required: true
      ) do
        OPTION(value: 'value') do
          I18n.t('permission.value')
        end
        if receiver_type == 'Role' && ['String', 'Enum'].include?(attr_type(@value.dig(:condition, :attr)))
          OPTION(value: 'domain') do
            I18n.t('permission.user_domain')
          end
          OPTION(value: 'user') do
            I18n.t('permission.user_field')
          end
        end
      end.on(:change) do |event|
        @errors[:condition].delete(:target) if @errors&.dig(:condition, :target)
        @value[:condition][:target] = event.target.value
        @value[:condition][:operation] = nil
        @value[:condition][:value] = nil
        @value[:condition][:context_field] = nil
        mutate
      end
    end

    def display_operator_selector
      SELECT(
        class: html_classes_for_value_editor(@errors&.dig(:condition, :operation)),
        value: @value.dig(:condition, :operation),
        disabled: !editable,
      ) do
        OPTION(value: nil)
        ::UneekPermission::Rule::DOMAIN_OPERATION_METHODS_BY_TYPE[attr_type(@value.dig(:condition, :attr))]&.each do |operation|
          OPTION(value: operation) do
            I18n.t("crm.filters_op.#{TRANSLATION_KEY_BY_OPERATION[operation]}")
          end
        end
      end.on(:change) do |event|
        @errors[:condition].delete(:operation) if @errors&.dig(:condition, :operation)
        @value[:condition][:operation] = event.target.value == '' ? nil : event.target.value
        @value[:condition][:value] = nil
        @value[:condition][:context_field] = nil
        mutate
      end
    end

    def display_footer
      DIV(class: 'd-flex') do
        DIV(class: 'flex-grow-1')
        BUTTON(class: 'btn btn-light') do
          I18n.t('shared.cancel')
        end.on(:click) do
          if rule.id
            init_value
            init_submission
            edit!(nil)
          else
            delete!(rule)
          end
        end
        BUTTON(class: 'btn btn-primary') do
          I18n.t('shared.save')
        end.on(:click) do
          if valid?
            modify_rule
            submit!(rule).then do |response|
              if response[:success]
                edit!(nil)
              else
                @errors ||= {}
                @errors[:server_error] = response[:message]
              end
              mutate
            end
          end
        end
      end
    end

    def show_errors
      DIV(class: 'alert alert-danger') do
        I18n.t("activerecord.errors.#{@errors[:server_error]}")
      end
    end

    def value_editor(type, target)
      case
      when type == 'Enum' && target != 'domain'
        enum_value_editor if enum_values&.any?
      when target == 'domain'
        domain_value_editor
      when target == 'user'
        user_field_editor
      when type == 'DateTime'
        Form::Element::Attribute::Date(
          form: self,
          prefix_path: [rule.id],
          attribute_name: 'condition[value]',
          value: @value.dig(:condition, :value),
          disabled: !editable,
          requirement: 'mandatory',
          valid: !@errors&.dig(:condition, :value),
          show_label: false
        ).on(:change) do |v, f, e|
          @errors[:condition].delete(:value) if @errors&.dig(:condition, :value)
          mutate @value[:condition][:value] = v
        end
      when type == 'Uuid'
        target_klass = klass_from_atrr(@value.dig(:condition, :attr))
        ::Form::Element::Association::BelongsTo(
          record: rule,
          form: self,
          value: @value[:condition][:value],
          prefix_path: [rule.id],
          attribute_name: 'condition[value]',
          target_klass_url: target_klass&.api_path,
          disabled: !editable,
          requirement: 'mandatory',
          valid: !@errors&.dig(:condition, :value),
          show_label: false,
          style: {minWidth: '33%'}
        ).on(:change) do |v, f, e|
          @errors[:condition].delete(:value) if @errors&.dig(:condition, :value)
          mutate @value[:condition][:value] = v.id
        end
      else
        INPUT(
          class: html_classes_for_value_editor(@errors&.dig(:condition, :value)),
          value: @value.dig(:condition, :value),
          disabled: !editable,
          required: true,
          placeholder: I18n.t('crm.filters_type.value', count: 1)
        ).on(:change) do |event|
          @errors[:condition].delete(:value) if @errors&.dig(:condition, :value)
          mutate @value[:condition][:value] = event.target.value == '' ? nil : event.target.value
        end
      end
    end

    def enum_values
      return nil unless other_params[:enum_values_proc]
      return @enum_values if @enum_values
      r = other_params[:enum_values_proc].call(@value.dig(:condition, :attr))
      @enum_values = r if r&.any?
    end

    def enum_value_editor
      SELECT(
        class: html_classes_for_value_editor(@errors&.dig(:condition, :value)),
        value: @value.dig(:condition, :value),
        disabled: !editable,
        required: true
      ) do
        OPTION(value: nil)
        enum_values.each do |e_value|
          OPTION(value: e_value[:name]) do
            e_value[:human_name]
          end
        end
      end.on(:change) do |event|
        @errors[:condition].delete(:value) if @errors&.dig(:condition, :value)
        mutate @value[:condition][:value] = event.target.value == '' ? nil : event.target.value
      end
    end

    def domain_value_editor
      context_editor('context_field') do
        if role_context_fields
          OPTION(value: nil)
          role_context_fields.each do |context_field|
            OPTION(value: context_field.name) do
              context_field.human_name
            end
          end
        end
      end
    end

    def html_classes_for_value_editor(has_error)
      return "form-control col-md-4 #{has_error ?  'is-invalid' : ''}"
    end

    def user_field_editor
      context_editor('user_field') do
        OPTION(value: nil)
        ['first_name', 'last_name', 'language', 'email'].each do |attr_name|
          OPTION(value: attr_name) do
            ::User.human_attribute_name(attr_name)
          end
        end
      end
    end

    def context_editor(target)
      t_sym = target.to_sym
      SELECT(
        class: html_classes_for_value_editor(@errors&.dig(:condition, t_sym)),
        value: @value.dig(:condition, t_sym),
        disabled: !editable,
        required: true,
        placeholder: I18n.t("permission.#{target}")
      ) do
        yield
      end.on(:change) do |event|
        @errors[:condition].delete(t_sym) if @errors&.dig(:condition, t_sym)
        mutate @value[:condition][t_sym] = event.target.value == '' ? nil : event.target.value
      end
    end

    def valid?
      @errors = {}
      @errors[:receiver] = I18n.t('permission.errors.receiver') unless @value[:receiver]
      if @value.dig(:condition,:attr)
        @errors[:condition] = {}
        @errors[:condition][:operation] = I18n.t('permission.errors.operation') if @value.dig(:condition, :operation).blank?
        if @value.dig(:condition,:operation)
          @errors[:condition][:target] = I18n.t('permission.errors.target') if @value.dig(:condition, :target).blank?
          @errors[:condition][:value] = I18n.t('permission.errors.value') if !['domain', 'user'].include?(@value.dig(:condition, :target)) && @value.dig(:condition,:value).blank?
          @errors[:condition][:context_field] = I18n.t('permission.errors.context_field') if @value.dig(:condition, :target) == 'domain' && @value.dig(:condition,:context_field).blank?
        end
      end
      mutate
      return @errors.empty? || @errors&.dig(:condition).blank?
    end

    def init_submission
      @value.each do |key, value|
        submission&.write([rule.id, key], value)
        submission.data[rule.id] ||= {}
        submission.data[rule.id][key] = value
      end
    end

    def attr_type(attr, k = klass)
      attr = attr.split('.') if attr.is_a? String
      return k.attributes.dig(attr[0], 'type') if attr.length == 1
      association_klass = k.reflect_on_association(attr[0])&.klass
      return attr_type(attr[1..-1], association_klass) if association_klass
    end

    def role_context_fields
      return [] unless @value[:receiver] && receiver_type == 'Role'
      return observe role_context_fields = RoleContextField.where(role_id: @value[:receiver].id).all
    end

    def modify_rule
      rule.send(:receiver_type=, receiver_type)
      rule.send(:receiver_id=, @value[:receiver]&.id)
      rule.send(:permission=, ['C','R','U','D'].map{|action| @value[:permission].include?(action) ? action : '_'}.join(''))
      rule.send(:instance_field=, @value.dig(:condition, :attr)) if @value.dig(:condition, :attr)
      rule.send(:context_field=, @value.dig(:condition, :context_field)) if @value.dig(:condition, :context_field)
      rule.send(:expression_method=, @value.dig(:condition, :operation)) if @value.dig(:condition, :operation) && @value.dig(:condition, :operation) != 'domain'
      rule.send(:expression_value=, @value.dig(:condition, :value)) if @value.dig(:condition, :value)
      rule.send(:user_field=, @value.dig(:condition, :user_field)) if @value.dig(:condition, :user_field)
    end

    def klass_from_atrr(attr, klass = self.klass)
      attr_ary = attr.split('.')
      return klass if attr_ary.length == 1
      return klass_from_atrr(attr_ary[1..-1].join('.'), klass.reflect_on_association(attr_ary[0])&.options[:class_name].safe_constantize)
    end

    def klass
      @klass ||= rule.klass_name.safe_constantize
    end

    def attribute_human_name(attr)
      klass.human_attribute_name(attr)
    end

    def receiver_type
      return unless @value && @value[:receiver]
      @value[:receiver].type || @value[:receiver].class&.name
    end

  end
end