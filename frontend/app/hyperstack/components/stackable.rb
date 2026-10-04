module Stackable

  class Base < HyperComponent
    include ::UrlHelper
  end

  class Container < Base

    param :style, default: {}
    param :css_class, default: 'vh-100'

    render { content }

    def layout(page_total = 3)
      init_pages(page_total)
      DIV(class: "#{self.css_class} container-fluid p-0", style: self.style) do
        DIV(class: 'row no-gutters h-100') do
          yield
        end
      end
    end

    def content
      layout{}
    end

    def init_pages(page_total)
      @@pages = {}
      @@page_total = page_total
    end

  end

  class Page < Base

    collect_other_params_as :others

    render { content }

    def content
     layout do
        children.map(&:render)
      end
    end

    before_mount do
      register_page
    end

    before_update do
      register_page
    end

    def layout
      DIV class: "#{col} stackable-page bg-light-yiq h-100 flex-column" do
        yield
      end
    end

    def col
      return others[:col] if others[:col]

      case page_total - @index
      when 1
        "col-sm-#{col_sm_size} col-lg-#{col_lg_size} d-flex"
      when 2
        "col-sm-#{col_sm_size} col-lg-#{col_lg_size} d-none d-sm-flex"
      when 3
        "col-sm-#{col_sm_size} col-lg-#{col_lg_size} d-none d-lg-flex"
      end
    end

    def col_sm_size
      if page_total > 1
        6
      else
        12
      end
    end

    def col_lg_size
      if index?
        return 12 / page_total
      else
        if large_page?
          return 6
        else
          return 3
        end
      end
    end

    def index?
      return true unless request
      return request.params[:action] == 'index'
    end

    def large_page?
      self.is_a?(LargePage)
    end

    def page_total
      Container.class_variable_get(:@@page_total)
    end

    def register_page
      Container.class_variable_get(:@@pages)[self] = true
      @index = pages.index(self)
    end

    def pages
      Container.class_variable_get(:@@pages).keys
    end

    def props_changed?(next_props)
      if (request && request.params[:action]) != @previous_action
        result = true
      else
        result = super
      end
      @previous_action = (request && request.params[:action])
      return result
    end

  end

  class LargePage < Page

    collect_other_params_as :others

    render { content }

    def content
      layout do
        children.render
      end
    end

  end

  class List < Base
    include Hyperstack::Router::Helpers

    param :items, type: Array
    param :active, allow_nil: true
    param :location, type: String

    render do
      DIV(class: 'stackable-list-group list-group flex-grow-1 overflow-auto') do
        items.try(:each) do |item|
          link_attributes = {
            class: [
              'list-group-item',
              'd-flex',
              'align-items-center',
              'border-0',
              'rounded-0',
              'list-group-item-action',
              (active && item[:id] == active) ? 'active' : '',
              item[:disabled] ? 'disabled' : '',
            ],
            style: {hyphens: 'auto'}
          }
          if item[:external_link]
            link_attributes[:target] = '_blank'
          end
          Link(item[:path] || [location, item[:id]].join('/'), link_attributes) do
            I class: "fa fa-#{item[:icon]} mr-1 fa-2x fa-fw"
            DIV(class: 'w-100 d-flex justify-content-between align-items-center') do
              if item[:subtitle]
                DIV do
                  DIV do
                    item[:title]
                  end
                  SMALL do
                    item[:subtitle]
                  end
                end
              elsif item[:count] || item[:count_loading]
                render_title_with_count(item)
              else
                SPAN do
                  item[:title]
                end
              end
              display_icons(item) unless item[:icons]&.empty?
            end
            if item[:right_icon]
              I class: "fa fa-#{item[:right_icon]}"
            end
          end
        end
      end
    end

    def render_title_with_count(item)
      DIV(class: 'd-flex justify-content-between align-items-center w-100') do
        SPAN { item[:title] }
        render_count_badge(item)
      end
    end

    def render_count_badge(item)
      if item[:count_loading]
        render_loading_spinner
      elsif item[:count]
        SPAN(class: 'badge badge-secondary ml-2') { item[:count] }
      end
    end

    def render_loading_spinner
      css_class = 'spinner-border spinner-border-sm w-4 h-4'
      SPAN(class: css_class)
    end

    def display_icons(item)
      DIV do
        item[:icons]&.each do |icon_data|
          I class: "#{icon_data[:icon]} ml-3", 'data-toggle': 'tooltip', 'title': icon_data[:tooltip]
        end
      end
    end
  end

  class PanelLink < Base
    include Hyperstack::Router::Helpers

    param :item
    param :location, default: nil

    render do
      link_attributes = {
        class: [
          'stackable-panel-link',
          'list-group-item',
          'bg-light-yiq',
          'd-flex',
          'align-items-center',
          'border-0',
          'rounded-0',
          'shadow-none',
          'list-group-item-action',
          item[:disabled] ? 'disabled' : '',
        ],
      }
      if item[:external_link]
        link_attributes[:target] = '_blank'
      end
      Link(item[:path] || [location, item[:id]].join('/'), link_attributes) do
        I class: "fa fa-#{item[:icon]} pr-4 fa-2x fa-fw"
        DIV class: 'd-flex justify-content-between w-100 align-items-center' do
          SPAN do
            item[:title]
          end
          I class: "fa fa-#{item[:right_icon] || 'chevron-right'}"
        end
      end
    end
  end

  class PanelLinkList < Base
    param :items
    param :location

    render do
      DIV(class: 'list-group flex-grow-1 overflow-auto') do
        items.try(:each) do |item|
          Stackable::PanelLink(item: item, location: location)
        end
      end
    end
  end

  class PageHeader < HyperComponent
    param :title
    param :level, default: 0
    param :back, allow_nil: true, type: String, default: nil

    render do
      DIV class: 'd-flex flex-column justify-content-center h-100' do
        DIV class: 'd-flex flex-row align-items-center' do
          if back
            Stackable::BackButton(href: back)
          else
            back_btn_placeholder
          end
          DIV class: 'd-flex align-items-center justify-content-between w-100' do
            Stackable::Heading(text: title, level: level)
            children.map(&:render)
          end
        end
      end
    end

    def back_btn_placeholder # for maintain header height
      SPAN(class: 'btn shadow-none text-left mr-2 pr-0 pl-0', style: {opacity: 0, width: 0}) do
        I(class: 'fa fa-chevron-left') {}
      end
    end
  end

  class Heading < Base

    param :text, default: nil
    param :level, default: 1

    render do
      send(text_tag, class: 'stackable-heading d-flex flex-column justify-content-center m-0') do
        text
      end
    end

    def text_tag
      if level < 2
        'SPAN'
      else
        'H2'
      end
    end

  end

  class BackButton < Base
    include Hyperstack::Router::Helpers

    param :href, allow_nil: true

    render do
      Link(href, class: 'btn btn-transparent-light-yiq shadow-none text-left mr-2', href: '#') do
        I(class: 'fa fa-chevron-left') {}
      end
    end
  end

  class Toolbar < Base
    render do
      DIV(class: 'p-2 w-100 border-bottom') do
        children.each(&:render)
      end
    end
  end

  class AddButton < Base
    include Hyperstack::Router::Helpers
    param :href

    render do
      Link(href, class: 'btn btn-primary rounded-circle position-absolute mb-3 mr-4', href: '#', style: {bottom: 0, right: 0, zIndex: '1000'}) do
        I(class: 'fa fa-plus') {}
      end
    end
  end

  class FormPanel < Base
    collect_other_params_as :attributes

    render { content }

    def content
      panel_layout do
        header
        container do
          form
        end
        footer
      end
    end

    def panel_layout
      DIV class: 'd-flex flex-column h-100' do
        yield
      end
    end

    def container
      DIV(class: 'container-fluid d-flex flex-column pt-3 flex-grow-1', style: {overflowY: 'auto', overflowX: 'hidden'}) do
        yield
      end
    end

    def header
      Stackable::Toolbar() do
        Stackable::PageHeader(title: attributes[:title], level: 2)
      end
    end

    def footer
    end

    def rescue_error_message
      panel_layout do
        super
      end
    end
  end

end
