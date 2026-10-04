require 'components/env_title'

class Crm
  module WithPageTitleAndLayoutSelector
    extend ActiveSupport::Concern

    included do
      include ::EnvTitle
      include ::SchemaLoading
    end

    def global_toolbar_left
      Portal(id: 'global-toolbar-left') do
        DIV(class: 'd-flex flex-row align-items-start') do
          DIV(class: "toolbar-title d-inline mb-1 text-light-yiq overflow-hidden") do
            page_title
          end
        end
        DIV(class: 'd-none d-md-flex') do
          layout_selector
        end
        env_title
      end
    end

    def layout_selector
      Layout::Selector::Dropdown(
        schema: schema,
        klass: klass,
        variant: 'primary',
        layout_id: layout_id,
        menu_item_id: request.params[:mi]
      ).on(:change) do |selected_layout_id|
        change_layout(selected_layout_id)
      end
    end

    def change_layout(selected_layout_id)
    end

    def page_title
      @page_title = current_request_name || current_menu_item&.label || klass.model_name.human(count: 2) if reset_page_title?
      return @page_title
    end

    def current_menu_item
      schema_menu&.items&.detect { |item| item.id == request.params[:mi] }
    end

    def schema_menu
      return nil if constants_reloading?
      observe User.current.menus.merge_where(schema_name: schema_name, name: 'crm').first
    end

    def constants_reloading?
      # when schema is changed components sometime rerender with an unloaded klass
      !klass.parent rescue true
    end

    def schema_name
      klass.parent.name.demodulize.underscore
    end

    def layouts_version_for_toolbar
      @layouts_version || 0
    end

    def current_request_name
      request.params[:query_name]
    end

    def reset_page_title?
      @page_title.blank? || @previous_query_name != request.params[:query_name] || @previous_klass != request.params[:klass] || @previous_menu_item_id != request.params[:mi]
    end
  end
end
