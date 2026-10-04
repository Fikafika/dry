class Crm
  class List < Index::Base

    render(DIV, class: 'crm-index') do
      global_toolbar
      redirect_to_index_with_a_right_panel_if_show_or_edit_record
      if dynamic_layout&.loaded?
        InfiniteScroll(DIV, class: 'grid-fluid grid-fluid-4 grid-gap-1 pt-2', items: relation.per(50), placeholder_height: 600, reload: @reload) do |record|
          DIV(class: 'border rounded p-3 cursor-pointer') do
            ::Crm::List::Item(record: record, layout: dynamic_layout, purpose: 'thumbnail')
          end.on(:click) do
            App.history.push(App.location.add_params(panel_param('right') => edit_url(record.class, record.id)))
          end
        end

        edit_query_dialog

        footer
      end
    end # end render

    def global_toolbar_right
      Portal(id: 'global-toolbar-right') do
        GroupDrop(variant: 'primary') do
          Toolbar::Button(target: new_url(klass), text: I18n.t('shared.new'), icon: 'plus', is_flex: true, "data-open-panel": 'right', variant: 'primary')
          Toolbar::Button(text: I18n.t('shared.refresh'), icon: 'redo', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reload
          end
          Toolbar::Button(text: I18n.t('crm.edit_query'), icon: 'filter', is_flex: true, target: "#edit_query_dialog", toggle: "modal", variant: 'primary')
          Toolbar::Button(text: I18n.t('crm.reset_filters'), icon: 'filter-circle-xmark', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reset_filters
          end
          toolbar_import_button
          toolbar_export_button(disabled: true)
          toolbar_delete_button(disabled: true)
        end
        Toolbar::Button(text: '', icon: 'search', is_flex: true, variant: 'primary').on(:click) do |event|
          event.prevent_default
          toggle_search_input
        end
      end
      global_search_input
    end

    def global_toolbar_bottom
      Portal(id: 'global-toolbar-bottom-menu') do
        Crm::BottomPanel(columns_render: 3) do
          bottom_panel_layout_selector_button
          BottomPanel::Button(target: '#edit_query_dialog', text: I18n.t('crm.edit_query'), icon: 'filter', toggle: "modal")
        end
        bottom_panel_layout_selector
      end
    end

    def dynamic_layout
      observe Dynamic::Layout.load(schema_name, 'show', 'thumbnail', klass.name)
    end

    class Item < ::HyperComponent
      include Hyperstack::Router::Helpers
      include ::Router::Resources

      collect_other_params_as :other_params

      param :record
      param :purpose, default: nil
      param :layout, default: nil

      render { content }

      def content
        return unless record
        Layout(dynamic_layout: dynamic_layout, request: request, record: record, class: other_params[:class])
      end

      def dynamic_layout
        observe (layout || Dynamic::Layout.load(schema_name, 'show', purpose, record))
      end

      def schema
        observe @schema ||= Dynamic::Schema.load(schema_name)
      end

      def schema_name
        @schema_name ||= record.class.name.split('::')[1].underscore
        return @schema_name
      end

      class FormParamsConverter < ::Layout::ParamsConverter
        converter_for 'Form'

        def apply(params, options = {})
          result = {
            schema_id: params[:schema],
            source_record: options.dig(:layout_params, :record)
          }
          return result
        end

      end

    end

  end
end
