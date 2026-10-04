require 'components/modal'

class Crm
  class Copy
    class RunModal < ::Modal
      include ::SchemaLoading

      render { content }

      def init
        if @event_params != @inited_for_event_params
          params = @event_params&.first || {}
          @records = params[:records] || (params[:record] ? [params[:record]] : [])
          @selected_mapping_id = nil
          @count = 1
          @source_klass = @records.first&.class
          @inited_for_event_params = @event_params
        end
      end

      def size
        'lg'
      end

      def title
        I18n.t('crm.copy.modal.title')
      end

      def body
        @available_mappings = nil
        return unless schema&.constants_loaded?
        if available_mappings.empty?
          DIV(class: 'alert alert-info') do
            I18n.t('crm.copy.modal.no_mapping')
          end
          return
        end

        @selected_mapping_id ||= available_mappings.first.id if available_mappings.one?
        DIV(class: 'modal-body') do
          DIV(class: 'row form-group') do
            LABEL(class: 'col-md-3 control-label') { I18n.t('crm.copy.modal.correspondance') }
            if available_mappings.one?
              DIV(class: 'col-md-9 form-control-plaintext p-0') { available_mappings.first.name }
            else
              SELECT(class: 'col-md-9 form-control', value: @selected_mapping_id || '') do
                OPTION(value: '') { '— ' + I18n.t('shared.select') + ' —' } if @selected_mapping_id.nil?
                available_mappings.each do |m|
                  OPTION(value: m.id) { "#{m.name}" }
                end
              end.on(:change) do |event|
                @selected_mapping_id = event.target.value
                mutate
              end
            end
          end

          DIV(class: 'row form-group') do
            LABEL(class: 'col-md-3 control-label') { I18n.t('crm.copy.modal.count') }
            INPUT(type: 'number', min: 1, max: max_count, value: @count, class: 'col-md-9 form-control').on(:change) do |event|
              @count = event.target.value.to_i.clamp(1, max_count)
              mutate
            end
          end

          if @records.size > 1
            DIV(class: 'alert alert-info') do
              I18n.t('crm.copy.modal.impact_summary', n: @records.size, total: @records.size * @count)
            end
          end
        end
      end

      def footer
        BUTTON(class: 'btn bg-light mr-2', type: 'button') do
          I18n.t('shared.cancel')
        end.on(:click) { cancel }

        BUTTON(class: 'btn btn-primary', type: 'button', disabled: !can_submit?) do
          I18n.t('layout.validate')
        end.on(:click) { submit }
      end

      def max_count
        ::Dynamic::Copy::Setting::MAX_COUNT_PER_SOURCE
      end

      def can_submit?
        @selected_mapping_id.present? && @records.any? && @count.to_i >= 1
      end

      def submit
        return unless can_submit?
        setting_class = schema.const::R::Copy::Setting
        source_records_attrs = @records.map { |r| { record_id: r.id, record_type: r.class.name } }
        setting = setting_class.new(
          mapping_id: @selected_mapping_id,
          count: @count,
          status: :to_do,
          source_records_attributes: source_records_attrs,
        )
        setting.save.then do |response|
          if response[:success]
            close
          else
            mutate
          end
        end
      end

      def available_mappings
        return @available_mappings if @available_mappings
        return [] unless @source_klass && schema&.constants_loaded?
        mapping_class = schema.const::R::Copy::Mapping
        @available_mappings = observe mapping_class.where(source_klass_name: @source_klass.name).all
      end

    end
  end
end
