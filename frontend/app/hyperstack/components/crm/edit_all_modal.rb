require 'components/modal'
require 'components/wait_for_completed_jobs'

class Crm
  class EditAllModal < ::HyperComponent
    param :id, default: nil
    param :relation, default: nil
    param :method_name, default: nil
    param :form_id, default: nil
    param :target_klass, default: nil

    collect_other_params_as :other_params

    fires :close
    fires :confirm

    render do
      modal_klass.create_element(
        {
          id: id,
          klass: klass,
          relation: relation,
          method_name: method_name,
          form_id: form_id,
        }.merge(**other_params)
      ).on(:close) do |*args|
        close!(*args)
      end.on(:confirm) do |*args|
        confirm!(*args)
      end.render
    end

    def modal_klass
      if klass&.reflect_on_association(method_name)&.collection?
        ::Crm::EditAllModal::Association::HasMany
      elsif method_name
        ::Crm::EditAllModal::Update
      else
        ::Crm::EditAllModal::Association::CreateUpdate
      end
    end

    def klass
      if target_klass
        target_klass
      else
        relation.is_a?(Class) ? relation : relation.klass
      end
    end

    class Base < ::Modal
      include WaitForCompletedJobs

      param :klass, default: nil
      param :relation, default: nil

      render { content }

      def show
        super && relation
      end

      def title
        return '' unless record_count.loaded?
      end

      def body
        # can be redefined
      end

      def footer
        DIV(class: 'd-flex flex-column w-100') do
          if @forced_async
            DIV(class: 'd-flex flex-row w-100') do
              DIV(class: 'alert alert-warning w-100') do
                I18n.t('crm.edit_all_modal.async_warning')
              end
            end
          end
          DIV(class: 'd-flex flex-row w-100') do
            unless @forced_async
              DIV(class: 'form-check') do
                INPUT(id: 'update-all-async', type: 'checkbox', class: 'form-check-input', checked: @async == true).on(:change) do |event|
                  mutate @async = ::Element[event.target.to_n].prop('checked')
                end
                LABEL(class: 'form-check-label', htmlFor: 'update-all-async') do
                  I18n.t('crm.edit_all_modal.async')
               end
              end
            end
            DIV(class: 'flex-grow-1'){}
            A(href: '#cancel', class:"btn bg-light mr-2", type: 'button') do
              cancel_btn_text
            end.on(:click) do |event|
              event.prevent_default
              cancel
            end
            A(href: '#confirm', class:"btn btn-primary #{'disabled' unless confirm_enabled?}", type: 'button') do
              SPAN do
                confirm_btn_text
              end
              I(class: 'ml-2 fa fa-spinner fa-pulse'){} if @loading
            end.on(:click) do |event|
              event.prevent_default
              confirm
            end
          end
       end
      end

      def async_threshold
        25
      end

      def confirm_enabled?
        @params&.any? && !@loading
      end

      def close
        @async = nil
        @params = nil
        @forced_async = false
        @loading = false
        super
      end

      def confirm
        return unless confirm_enabled?
        promise = self.get_promise
        if promise && !@async
          promise.then do
            @loading = false
            super
          end
          mutate @loading = true
        else
          super
        end
      end

      def get_promise
        # can be redefined
      end

      def default_size
        'lg'
      end

      def record_count
        observe relation.count
      end
    end

    class Update < Base
      param :method_name, default: nil

      render { content }

      def show
        super && method_name
      end

      def title
        super
        I18n.t(
          'crm.update_records',
          count: record_count.to_i,
          klass_name: klass.model_name.human(count: record_count).downcase,
          gender: klass.model_name.try(:gender)
        )
      end

      def body
        if @async.nil? && record_count.loaded? && record_count.to_i > async_threshold
          @forced_async = true
          @async = true
        end
        Form(record: record) do
          form_elements
        end.on(:change) do |form|
          @params = form.submission.params.values.first
          mutate
        end
      end

      def form_elements
        ::Form::Element::Association::BelongsTo(attribute_name: :change, mode: :nested_form, show_item_header: false, show_label: false, show_item_separator: false) do
          element_attributes = default_element_attributes
          element_attributes[:editor] = :select if klass.attributes.dig(method_name, :type) == 'Boolean'
          ::Form::Element.klass_from_method_name(klass, method_name).create_element(element_attributes).render
        end
        ::Form::Element::Attribute::Boolean(
          attribute_name: :delete_values,
          label: I18n.t('shared.clear'),
        )
      end

      def default_element_attributes
        {
          klass_name: klass.name,
          attribute_name: attribute_name,
          possible_values: possible_values,
          disabled: delete_values?
        }
      end

      def attribute_name
        reflection = klass&.reflect_on_association(method_name)
        if reflection && !reflection.collection? && !reflection.options[:polymorphic]
          "#{method_name}_id"
        else
          method_name
        end
      end

      def get_promise
        if delete_values?
          return delete_values
        else
          return update
        end
      end

      def delete_values
        return relation.update_all({attribute_name => nil}, update_options)
      end

      def update_options
        wait_for_completed_jobs_options.merge(
          wait_for_completed_jobs: @async ? nil : 10000, # increase time if not async, disable wait if async
          async: @async,
        )
      end

      def update
        return unless update_params
        return relation.update_all(update_params, update_options)
      end

      def update_params
        change_attributes = @params[:change_attributes]&.first
        return unless change_attributes&.dig(attribute_name).present?
        return change_attributes
      end

      def delete_values?
        @params.try(:[], :delete_values) == '1'
      end

      def record
        @record ||= BulkUpdate.new(
          change: klass.new(type: klass.name),
          add: klass.new(type: klass.name),
          remove: klass.new(type: klass.name),
        )
      end

      def possible_values
        return klass.attributes.dig(method_name, :possible_values, I18n.locale)
      end

    end

    module Association
      class HasMany < EditAllModal::Update

        render { content }

        def form_elements
          DIV(class: 'mb-3') do
            klass.human_attribute_name(method_name)
          end
          ::Form::Element::Association::BelongsTo(attribute_name: :add, mode: :nested_form, show_item_header: false, show_label: false, show_item_separator: false) do
            ::Form::Element.klass_from_method_name(klass, method_name).create_element(
              label: I18n.t('shared.add'),
              klass: klass,
              attribute_name: method_name,
              disabled: delete_values?,
            ).render
          end
          ::Form::Element::Association::BelongsTo(attribute_name: :remove, mode: :nested_form, show_item_header: false, show_label: false, show_item_separator: false) do
            ::Form::Element.klass_from_method_name(klass, method_name).create_element(
              label: I18n.t('shared.remove'),
              klass: klass,
              attribute_name: method_name,
              disabled: delete_values?,
            ).render
          end
          ::Form::Element::Attribute::Boolean(
            attribute_name: :delete_values,
            label: I18n.t('shared.clear'),
          )
        end

        def delete_values
          return relation.update_all({association_attributes_method => {_remove: 'all'}}, update_options)
        end

        def update_options
          super.merge(differential: true)
        end

        def association_attributes_method
          "#{method_name}_associations_attributes"
        end

        def update_params
          nested_attribute_method = "#{method_name}_attributes"
          to_add = @params[:add_attributes]&.first&.dig(nested_attribute_method)&.map{|e| to_association_target(e) }
          to_remove = @params[:remove_attributes]&.first&.dig(nested_attribute_method)&.map{|e| to_association_target(e) }
          return unless to_add&.any? || to_remove&.any?
          return {
            association_attributes_method => {
              :_add => to_add,
              :_remove => to_remove,
            }
          }
        end

        def to_association_target(attrs)
          result = {}
          result[:association_target_id] = attrs[:id]
          result[:association_target_type] = attrs[:type] || klass.reflect_on_association(method_name).klass.name
          return result
        end

      end

      class CreateUpdate < Base
        include ::SchemaLoading

        param :form_id, default: nil
        param :on_conflict_element_id, default: nil

        render { content }

        before_render do
          @form_id = form_id unless @form_id
          dynamic_forms_for_association if form_id
          current_form
        end

        def show
          super && klass
        end

        def title
          super
          I18n.t(
            'crm.submit_all_records',
            count: @form_id ? record_count.to_i : 0,
            klass_name: klass.model_name.human(count: record_count).downcase,
            form_name: current_form&.human_name,
            gender: klass.model_name.try(:gender)
          )
        end

        def body
          if @async.nil? && record_count.loaded? && record_count.to_i > async_threshold
            @forced_async = true
            @async = true
          end
          unless form_id
            Form(record: ::HyperResource::Base.new) do
              Form::Element::Attribute::Enum(
                label: I18n.t('activerecord.models.dynamic/form.one'),
                attribute_name: 'form_id',
                possible_values: possible_form_values,
                default_value: @form_id,
                accept_empty_value: false,
              )
            end.on(:change) do |form|
              @form_id = form.submission.params.values.first[:form_id]
              @current_form = nil
              mutate
            end
          end
          Form(dynamic_form_id: @form_id, schema_id: schema.name) if @form_id
        end

        def dynamic_forms_for_association
          observe @forms ||= Dynamic::Form.with_action(:submit_all).where(
            schema_id: schema.name,
            association_klass_name: klass.name,
          ).all
        end

        def possible_form_values
          @possible_form_values if @possible_form_values
          @forms = nil
          dynamic_forms_for_association
          @possible_form_values = @forms.map {|f| {label: f.human_name, value: f.id}}
        end

        def get_promise
          dynamic_form = Form.current.dynamic_form
          return unless dynamic_form
          submission = Form.current.submission
          params = {
            async: @async,
            klass_id: klass.name.split('::').last,
            form_name: current_form.human_name,
          }
          params[:relation_scope] = relation.scope if !relation.is_a?(Class) && relation.scope
          params[:on_conflict_element_id] = on_conflict_element_id if on_conflict_element_id
          return dynamic_form.submit_all(submission.params.merge(params))
        end

        def current_form
          @current_form ||= @forms&.detect {|f| f.id == @form_id} if @form_id
        end

        def confirm_enabled?
          @form_id&.present?
        end

        def close
          @form_id = nil
          @current_form = nil
          @possible_form_values = nil
          super
        end

        def async_threshold
          0
        end

      end
    end

    class BulkUpdate < ::HyperResource::Base
      belongs_to :add
      belongs_to :remove
      belongs_to :change
      attribute :delete_values, :boolean, default: false
    end

  end
end
