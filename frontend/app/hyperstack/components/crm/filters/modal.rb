require 'components/crm/filters/normalization'
require 'components/crm/filters/find_and_update'

class Crm
  module Filters
    class Modal < HyperComponent
      extend ::Crm::Filters::Normalization
      include ::Crm::Filters::FindAndUpdate

      param :attr, default: nil
      param :value, default: nil
      param :klass
      param :show

      param :search_query

      fires :launch_search
      fires :cancel

      collect_other_params_as :other_params

      after_update do
        ::Element.find('#filter_modal').modal(show ? 'show' : 'hide')
      end

      after_mount do
        ::Element.find('#filter_modal').on('hidden.bs.modal') do |event|
          after(0.1) do
            next if @confirm
            @filters_list = nil
            cancel!
          end
        end
      end

      def init_filters
        return if @filters_list

        if attr
          attr_filters = extract_filter_from_search_query(search_query, attr)
        end

        @filters_list = List.convert_from_hash(attr_filters || {})

        if @filters_list.length == 0 || @filters_list == [["and", nil, nil]]
          @filters_list = [["and", default_operator, value]]
        end

      end

      def default_operator
        column&.default_operator || 'contains'
      end

      def column
        klass.datatable_column_by_name[attr]
      end

      def filters_menu
        column&.filters_menu || []
      end

      render do
        DIV(id: "filter_modal", class: "modal px-0", role: 'dialog', 'data-backdrop': false) do
          next unless show
          @confirm = false

          init_filters
          backdrop
          DIV(class: "modal-dialog modal-lg shadow-sm", role: 'document', style: {zIndex: 10000}) do
            DIV(class: 'modal-content') do
              if klass.human_attribute_name(attr)
                DIV(class: 'modal-header') do
                  H5(class: 'modal-title') do
                    title
                  end
                  BUTTON(class: "close", type: "button", "data-dimiss": "modal", "aria-label": 'Close') do
                    SPAN("aria-hidden": true, dangerously_set_inner_HTML: {__html: '&times;'})
                  end.on(:click) do |event|
                    cancel!
                  end
                end
              end
              DIV(class: 'modal-body') do
                Filters::List(
                  root_klass: klass,
                  list: @filters_list,
                  column: column,
                  button_width: '70px',
                  menu_width: '160px',
                ).on(:change) do |filters|
                  @filters_list = filters
                  mutate
                end
              end
              DIV(class:"modal-footer") do
                BUTTON(class:"btn bg-light", type:"button", "data-dismiss":"modal") do
                  I18n.t('shared.cancel')
                end.on(:click) do |event|
                  @filters_list = nil
                  cancel!
                end
                BUTTON(class:"btn btn-primary", type:"button", "data-dismiss":"modal") do
                  I18n.t('shared.confirm')
                end.on(:click) do |event|
                  @confirm = true
                  launch_query
                end
              end
            end
          end
        end
      end

      def title
        column.human_path.each_with_index do |attr, i|
          SPAN do
            attr
          end
          I(class: 'fa fa-chevron-right mx-2') do
          end unless i == column.human_path.length - 1
        end
      end

      def backdrop
        DIV(class: 'modal-backdrop w-100 h-100 show') do
        end.on(:click) do |event|
          event.stop_propagation
          cancel!
        end
      end

      def launch_query
        filter_value = self.class.nested_array_to_hash(@filters_list) if @filters_list.present?
        update_filter_in_search_query(search_query, attr, filter_value)
        @filters_list = nil
        launch_search!
      end

      # --------------------------- INVERSE

      def add_close_listener_to_body
        ::Element['body'].on('click.filterModal') do |event|
          if ::Element.find('#filter_modal .modal-dialog').length > 0
            unless !unmouted? || self.jq_node.has(::Element[event.target]).length > 0
              cancel!
            end
          end
        end
      end

      def remove_close_listener_from_body
        ::Element['body'].off('click.filterModal')
      end
    end
  end
end
