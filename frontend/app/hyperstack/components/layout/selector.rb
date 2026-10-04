class Layout
  module Selector
    class Base < ::HyperComponent
      include Hyperstack::Router::Helpers

      param :schema, default: {}
      param :layout_id
      param :menu_item_id
      param :klass

      param :variant, default: 'light-yiq', type: String

      fires :change

      before_mount do
        @layout_listener_id = listen_to_layout_changes
      end

      before_unmount do
        LayoutEvent.off(:layout_changed, @layout_listener_id) if @layout_listener_id
      end

      def listen_to_layout_changes
        return unless defined?(LayoutEvent)
        LayoutEvent.on(:layout_changed) do
          @layouts = nil
          @items = nil
          mutate
        end
      end

      def items
        return [] unless layouts.loaded?
        return @items if @items
        @items = layouts.map do |l|
          {
            text: l.human_name,
            id: l.id,
          }
        end
        return @items
      end

      def layouts_relation
        @layouts_relation ||= Dynamic::Layout
          .with_action('index')
          .for_menu_item(menu_item_id)
          .where(schema_id: schema.name, klass_name: klass.name)
          .order(id: :asc)
      end

      def layouts
        observe @layouts ||= layouts_relation.all
      end

      def ready?
        klass && schema && items.any?
      end

      def can_create_layout?
        true
      end
    end

    class Dropdown < Base

      render do
        next unless ready?

        Toolbar::Dropdown(
          text: current_text,
          icon: 'desktop',
          text_params: { class: 'ml-1 d-none d-md-inline-flex' },
          btn_params: { class: "btn btn-transparent-#{variant} shadow-none", title: current_text },
        ) do
          items.each { |m| render_item(m) }
          new_layout_item if can_create_layout?
        end
      end

      def render_item(m)
        Link('#', class: 'dropdown-item') do
          m[:text]
        end.on(:click) do |event|
          event.prevent_default
          change!(m[:id])
        end
      end

      def current_text
        items.detect{|i| i[:id] == layout_id}.try(:[], :text) || I18n.t('layout.selector.display')
      end

      def new_layout_item
        DIV(class: 'dropdown-divider'){}
        render_item({
          text: I18n.t('layout.selector.new_layout'),
          id: 'new',
        })
      end

    end

    class BottomList < Base

      render do
        next unless ready?

        items.each { |m| render_item(m) }
      end

      def render_item(m)
        Crm::BottomPanel::Button(
          text: m[:text],
          icon: m[:icon],
          class: layout_id && m[:id] == layout_id ? 'active' : '',
        ).on(:click) do |event|
          event.prevent_default
          change!(m[:id])
        end
      end
    end
  end
end
