class AppMenu < HyperComponent

  param :id
  param :desktop, default: []
  param :mobile, default: []

  fires :close
  fires :open

  render do
    SidePanel(id: id, side: 'left', backdrop: true) do
      if desktop&.any?
        DIV(class:'d-none d-md-block') do
          Tabs(id: 'desktop-tabs', menu: desktop).on(:dismiss_modal) do
            ::Element.find("##{id}").modal('hide')
          end
        end
      end
      if mobile&.any?
        DIV(class: 'd-md-none h-100') do
          Tabs(id: 'mobile-tabs', menu: mobile).on(:dismiss_modal) do
            ::Element.find("##{id}").modal('hide')
          end
        end
      end
    end.on(:open) do
      open!
    end.on(:close) do
      close!
    end
  end

  class Tabs < HyperComponent
    param :id, default: nil
    param :menu, default: []

    fires :dismiss_modal

    render do
      DIV(class:"container") do
        DIV(class: "row") do
          DIV(class:"col-2 px-0") do
            UL(id: "tabs", class: "nav nav-tabs nav-fill flex-column", role: "tablist") do
              menu.each do |h|
                LI(class:"nav-item") do
                  A(class: "btn w-100 border-0 rounded-0 btn-transparent-light-yiq #{(h[:id] == menu.first[:id]) ? 'active' : ''}", "data-toggle": "tab", href: "##{id}-tab-#{h[:id]}", role: "tab", title: h[:text]) do
                    SPAN(class: "fa fa-#{h[:icon]} fa-fw") do
                    end
                  end
                end
              end
            end
          end
          DIV(class:"col-10 px-0") do
            DIV(class:"tab-content") do
              menu.each do |h|
                DIV(id: "#{id}-tab-#{h[:id]}", class: "tab-pane fade #{(h[:id] == menu.first[:id]) ? 'show active' : ''} ", role:"tabpanel") do
                  build_menus(h[:id], h[:menu])
                end.on(:click) do
                  dismiss_modal!
                end
              end
            end
          end
        end
      end
    end

    def build_menus(id, menu, o = {show: true})
      return unless menu.try(:any?)

      build_menu(id, menu, o)

      menu.each do |m|
        build_menus(menu_id(id, m), m[:menu], {parent_id: id})
      end
    end

    def build_menu(id, menu, o = {})
      DIV(id: id, class: "collapse #{o[:show] ? 'show' : nil} width") do
        DIV(class: 'list-group') do
          Item(
            text: I18n.t('shared.back'),
            icon: 'chevron-left',
            target: [id, o[:parent_id]].compact.map{|t| "##{t}" }.join(','),
            toggle: 'collapse',
          ) if o[:parent_id]
          menu.each do |m|
            if m[:type] == 'group'
              DIV(class: 'text-muted width px-2 pt-2') do
                m[:text]
              end
              build_menus(id, m[:menu])
            else
              Item(
                text: m[:text],
                icon: m[:icon],
                right_icon: m[:menu] ? 'chevron-right' : nil,
                target: m[:menu] ?  "##{id}, ##{menu_id(id, m)}" :  m[:target],
                toggle: m[:menu] ? 'collapse' : nil,
                external: m[:external] ? true : false,
                image: m[:image],
              )
            end
          end
        end
      end
    end

    def menu_id(id, m)
      "#{id}-#{m[:text]&.gsub(/\s/, '-')}"
    end
  end

  class Item < HyperComponent
    include Hyperstack::Router::Helpers

    param :text, default: nil, type: String
    param :icon, default: nil
    param :image, default: nil
    param :toggle, default: ''
    param :target, default: ''
    param :external, default: false, type: Boolean

    collect_other_params_as :other_params

    fires :click

    render() do
      css_class = "btn btn-transparent-light-yiq border-0 rounded-0 text-break shadow-none"
      link(target, class_name: css_class, 'data-toggle': toggle, external: external) do
        DIV(class: 'd-flex flex-row justify-content-start align-items-center') do
          if image.present? && !image_error?
            IMG(image_params)
          else
            I(class: "#{'mr-2' if text.present?} fa fa-#{icon || 'square'} fa-fw")
          end
          if text.present?
            text
          end
        end
      end.on(:click) do |event|
        click!(event)
      end
    end

    def link(uri, options = {})
      options_ = options.except(:external)
      if options[:external]
        A(href: uri, **options_) do
          yield
        end
      else
        Link(uri, **options_) do
          yield
        end
      end
    end

    def image_error?
      @image_error
    end

    def image_params
      return @image_params if @image_params
      result = {}
      result[:src] ||= image
      result[:alt] ||= text
      class_name = result.delete(:class)
      result[:class_name] = "#{class_name} fa-fw #{'mr-2' if text.present?}"
      result[:onError] = Proc.new{|event| @image_error = true; mutate } if icon.present?
      return @image_params = result
    end

  end

end
