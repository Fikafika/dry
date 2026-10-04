# backtick_javascript: true

require 'components/error_boundary'

class Crm
  class Sheet
    class TabBar < ::HyperComponent
      include Hyperstack::Router::Helpers

      render do
        ErrorBoundary do
          content
        end
      end

      after_mount do
        after do
          init_bootstrap
          make_responsive
          activate_first_tab
        end
      end

      after_update do
        if tabs_changed?
          init_bootstrap
          make_responsive
          activate_first_tab
        end
      end

      def init_bootstrap
        self.jq_node.on('shown.bs.tab', '.nav-tabs [data-toggle="tab"]') do |event|
          self.jq_node.find(event.target.attr('href')).trigger('shown.bs.tab-pane')
        end
      end

      def activate_first_tab
        links = self.jq_node.find('[data-toggle="tab"]')
        return unless links.length > 0
        links.first.tab('show')
      end

      def no_active_tab?
        self.jq_node.find('.tab-pane.active').length == 0
      end

      def content
        DIV(key: tabs_key) do
          UL(class: 'nav nav-tabs pl-2 pr-2', role: 'tablist') do
            children.each do |tab|
              LI(key: "nav-item-#{tab.props[:association_id] || tab.props[:name]}", class: 'nav-item') do
                Link(
                  "##{tab.props[:name]}",
                  class: "nav-link #{'active' if tab.props[:active]} text-capitalize-first-letter",
                  'data-toggle': 'tab',
                  'aria-controls': tab.props[:name],
                  'aria-selected': tab.props[:active],
                ) do
                  SPAN(class: "fa fa-#{tab.props[:icon]} pr-2"){} if tab.props[:icon]
                  tab_title(tab)
                end
              end
            end
          end
          DIV(class: 'tab-content') do
            children.each do |tab|
              tab.render(key: "tab-pane-#{tab.props[:association_id] || tab.props[:name]}")
            end
          end
        end
      end

      def tab_title(tab)
        tab.props[:translations]&.dig(I18n.locale, :title) || tab.props[:name]
      end

      def tabs_key
        return "tabs" unless self.props[:children].respond_to?(:detect)
        "tabs-#{self.props[:children]&.detect{|c| c.props[:association_id] }&.props.try(:[], :association_id)}"
      end

      def tabs_changed?
        result = @previous_tabs_key != tabs_key
        @previous_tabs_key = tabs_key if result
        return result
      end

      def make_responsive
        self.jq_node.find('.nav-tabs').responsive_tabs
        workaround_remove_child
      end

      def workaround_remove_child
        `$(#{self.dom_node}).find('.nav-tabs').each(function() {
          if (!this.originalRemoveChild) {
            this.originalRemoveChild = this.removeChild;
            this.removeChild = function(child) {
              var result;
              try {
                result = this.originalRemoveChild.apply(this, arguments);
              } catch(error) {
                console.log(this, child)
              }
              return result;
            }
          }
        })`
      end

      class Tab < ::HyperComponent

        param :name
        state_accessor :active
        collect_other_params_as :other_params

        after_mount do
          self.jq_node.on('shown.bs.tab-pane') do
            self.active = true
          end
          self.jq_node.on('hidden.bs.tab-pane') do
            self.active = false
          end
        end

        render { content }

        def content
          DIV(
            id: name,
            class: "tab-pane fade #{'show active' if active?}",
            role: 'tabpanel',
          ) do
            if active?
              children.render
            end
          end
        end

        def active?
          self.active.nil? ? self.props[:active] : self.active
        end

        class InfiniteScrollerParamsConverter < ::Layout::ParamsConverter
          converter_for 'InfiniteScroller'

          def apply(params, options = {})
            request = options[:layout_params][:request]
            schema = ::Dynamic::Schema.load(request.params[:schema])
            klass = schema.const.const_get_by_route_key(request.params[:klass])
            record = klass.find(request.params[:id])
            all_items = record.dynamic_associations.for_schema_associations(options[:schema_association_ids])
            result = {
              items: all_items,
            }

            return result
          end

        end

      end

    end
  end
end
