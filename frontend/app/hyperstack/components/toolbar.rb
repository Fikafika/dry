class Toolbar < HyperComponent

  collect_other_params_as :other_params

  render() do
    DIV(class: other_params[:className], style: other_params[:style]) do
      children.each(&:render)
    end
  end

  class Button < HyperComponent
    include Hyperstack::Router::Helpers

    param :toggle, default: nil
    param :dismiss, default: nil
    param :target, default: ''
    param :is_flex, default: false, type: Boolean
    param :variant, default: 'light-yiq', type: String
    param :state, default: ''
    param :shape, default: '', type: String
    param :size, default: '', type: String
    param :text_break, default: false
    param :icon_size, default: nil

    collect_other_params_as :other_params

    render{ content }

    def content
      Link(target, link_params) do
        DIV(class: 'd-flex flex-row justify-content-start align-items-center h-100') do
          I(class: "#{'pr-2 ' if text.present?}fa fa-#{icon} #{"fa-#{icon_size} " if icon_size}fa-fw")
          if text.present?
            SPAN(class: "#{'d-none d-lg-flex' if is_flex}") do
              text
            end
          end
        end
      end
    end

    def link_params
      additional_params = {}
      additional_params[:class_name] = css_class if css_class.present?
      additional_params[:'data-toggle'] = toggle if toggle
      additional_params[:'data-dismiss'] = dismiss if dismiss
      additional_params[:'data-open-panel'] = other_params[:'data-open-panel'] if other_params.has_key?(:'data-open-panel')

      return other_params.except(:text, :icon).merge(additional_params)
    end

    def icon
      other_params[:icon]
    end

    def text
      other_params[:text]
    end

    def css_class
      "btn btn-transparent-#{variant} #{shape} #{state} #{text_break ? text_break : ''} #{other_params[:className]} shadow-none"
    end
  end

  class Dropdown < HyperComponent
    include Hyperstack::Router::Helpers

    param :icon, default: ''
    param :text, default: ''

    collect_other_params_as :other_params

    before_new_params do
      @btn_params = nil
      @text_params = nil
      @image_params = nil
      @icon_params = nil
      @dropdown_params = nil
      @image_error = nil
    end

    render { content }

    def content
      DIV(dropdown_params) do
        Link('#', btn_params) do
          DIV(class: 'd-inline-block') do
            if image.present? && !@image_error
              IMG(image_params)
            elsif icon.present?
              I(icon_params)
            end
            SPAN(text_params) { text } if text.present?
          end
        end
        DIV(class: 'dropdown-menu') do
          children.render
        end
      end
    end

    def btn_params
      return @btn_params if @btn_params
      result = other_params[:btn_params] || {}
      class_name = result.delete(:class)
      result[:class_name] = "btn dropdown-toggle #{class_name}"
      result[:"data-toggle"] = "dropdown"
      return @btn_params = result
    end

    def text_params
      @text_params ||= other_params[:text_params] || {}
    end

    def image
      other_params[:image]
    end

    def image_params
      return @image_params if @image_params
      result = other_params[:image_params] || {}
      result[:src] ||= image
      result[:alt] ||= ''
      class_name = result.delete(:class)
      result[:class_name] = "#{class_name} fa-fw"
      result[:onError] = Proc.new{|event| @image_error = true; mutate } if icon.present?
      return @image_params = result
    end

    def icon_params
      return @icon_params if @icon_params
      result = other_params[:icon_params] || {}
      class_name = result.delete(:class)
      variant = result.delete(:variant)
      result[:class_name] = "#{'pr-2 ' if text.present?}fa#{variant} fa-#{icon} fa-fw#{" #{class_name}" if class_name}"
      return @icon_params = result
    end

    def dropdown_params
      return @dropdown_params if @dropdown_params
      result = {}
      other_params.each do |k,v|
        next if ['btn_params', 'text_params', 'icon_params', 'image', 'image_params'].include?(k)
        result[k] = v
      end
      class_name = result.delete(:class)
      result[:class_name] = "dropdown#{" #{class_name}" if class_name}"
      return @dropdown_params = result
    end

    class Item < HyperComponent
      include Hyperstack::Router::Helpers

      param :target, default: nil
      param :icon, default: ''
      param :text, default: ''
      param :disabled, default: false

      collect_other_params_as :other_params

      before_new_params do
        @item_params = nil
        @icon_params = nil
      end

      render do
        Link(target, **item_params) do
          I(icon_params) if icon.present?
          SPAN(text_params) { text } if text.present?
        end
      end

      def item_params
        return @item_params if @item_params
        result = {}
        other_params.each do |k,v|
          next if ['text_params', 'icon_params', 'image', 'image_params'].include?(k)
          result[k] = v
        end
        class_name = result.delete(:class)
        result[:class_name] = "dropdown-item#{" #{class_name}" if class_name}#{' disabled' if disabled}"
        return @item_params = result
      end

      def icon_params
        return @icon_params if @icon_params
        result = other_params[:icon_params] || {}
        class_name = result.delete(:class)
        variant = result.delete(:variant)
        result[:class_name] = "#{'pr-2 ' if text.present?}fa#{variant} fa-#{icon} fa-fw#{" #{class_name}" if class_name}"
        return @icon_params = result
      end

      def text_params
        other_params[:text_params] || {}
      end

    end

  end

  class UserButton < HyperComponent

    include Hyperstack::Router::Helpers

    collect_other_params_as :other_params

    def user
      observe User.current
    end

    before_mount do
      user
    end

    render() do
      DIV(class: 'dropdown') do
        if user.connected?
          connected = true
          text = user.name_or_login
          image = "#{user.photo_url}?style=twenty" if user.has_photo
        else
          connected = false
          text = I18n.t('toolbar.user_button.disconnected')
          icon_variant = 'r'
        end

        Dropdown(
          text: text,
          image: image,
          icon: 'user',
          icon_params: { variant: icon_variant },
          text_params: { class: 'ml-1 d-none d-md-inline-flex' },
          image_params: { class: 'align-top', width: 20, height: 20 },
          btn_params: { class: "#{ %Q[btn-transparent-#{other_params[:variant]}] if other_params[:variant]} shadow-none", title: text},
        ) do
          if Hyperstack.env == 'development'
            Link('#', class: 'dropdown-item') do
              I18n.t('shared.reload')
            end.on(:click) do |event|
              event.prevent_default
              App.reload
            end
          end
          Link('#', class: 'dropdown-item') do
            I18n.t('toolbar.user_button.disconnect')
          end.on(:click) do |event|
            event.prevent_default
            user.sign_out
          end
        end
      end
    end

  end

end
