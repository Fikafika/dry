module Permission
  class Manager < HyperComponent

    DEFAULT_RULE_PARAMS = {
      id: nil,
      permission: '____'
    }.freeze

    param :rules, default: []
    param :attributes, default: []
    param :associations, default: []
    param :possible_attributes_values, default: []
    param :params_for_new_record, default: DEFAULT_RULE_PARAMS
    param :on_instance, type: ::Boolean, default: false

    collect_other_params_as :other_params

    before_mount do
      merge_default_params_for_new_record
    end

    after_new_params do
      merge_default_params_for_new_record
    end

    def merge_default_params_for_new_record
      @merged_params_for_new_record = DEFAULT_RULE_PARAMS.dup unless @merged_params_for_new_record
      @merged_params_for_new_record.merge!(params_for_new_record)
    end

    render { content }

    def content
      DIV(class: 'overflow-auto h-100', id: 'rule_management') do
        rules.reverse.each do |record|
          DIV(class: 'list-group') do
            Permission::Form(
              key: (record.id ? record.id : 'new'),
              rule: record,
              attrs: attributes,
              associations: associations,
              editable: (record == current_rule_edited),
              on_instance: on_instance,
              receiver: record.receiver,
              possible_attributes_values: possible_attributes_values,
              **other_params
            ).on(:submit) do |new_record|
              new_record.save.then do |response|
                if response[:success]
                  record = new_record
                else
                  response = response.merge(new_record.errors)
                end
                mutate
                response
              end
            end.on(:delete) do |record|
              if record.id
                Modal.confirm(title: I18n.t('shared.delete'), text: I18n.t('shared.ask_for_confirmation')) do
                  record.destroy.then do |response|
                    if response[:success]
                      mutate rules.delete(record)
                    end
                  end
                end
              else
                mutate rules.delete(record)
              end
            end.on(:edit) do |record|
              mutate @current_rule_edited = record
            end
          end
        end
      end
      if current_rule_edited.nil?
        add_button
      end
    end

    def add_button
      BUTTON(class: 'btn btn-primary rounded-circle position-absolute mb-3 mr-4 z-0', style: {bottom: 0, right: 0}) do
        I(class: 'fa fa-plus')
      end.on(:click) do
        scroll_to_bottom
        rules.unshift(new_record)
        mutate
      end
    end

    def new_record
      ::UneekPermission::Rule.new(@merged_params_for_new_record)
    end

    def scroll_to_bottom
      ::Element.find('#rule_management').scrollTop(::Element.find('#rule_management').prop('scrollHeight'))
    end

    def current_rule_edited
      @current_rule_edited || rules.detect {|record| record.id.nil?}
    end

  end
end
