class IconButton < HyperComponent
  include Hyperstack::Router::Helpers

  param :icon, default: ''#, type: String
  param :right_icon, default: nil
  param :text, default: '', type: String
  param :toggle, default: nil  # TODO replace by data
  param :dismiss, default: nil  # TODO replace by data
  param :target, default: ''#, type: String
  param :is_flex, default: false, type: Boolean
  param :role, default: '', type: String
  param :variant, default: 'light', type: String
  param :state, default: ''#, type: String
  param :shape, default: 'border-0 rounded-0', type: String
  param :size, default: '', type: String
  param :text_break, default: 'text-break', type: String
  param :icon_size, default:'', type: String
  # param :data, default: nil

  collect_other_params_as :other_params

  fires :click

  def with_right_icon(has_right_icon)
    if has_right_icon
      DIV(class: 'd-flex flex-row justify-content-between align-items-center') do
        yield
        I(class: "ib-icon ib-icon-right #{is_flex ? 'd-none d-lg-flex' : ''} pl-2 fa fa-#{right_icon}")
      end
    else
      yield
    end
  end

  render() do
    css_class = "ib btn btn-#{variant} #{shape} #{state} #{text_break} #{other_params[:className]}"
    link_params = {class_name: css_class}
    link_params['data-toggle'] = toggle if toggle
    link_params['data-dismiss'] = dismiss if dismiss
    other_params&.each{|k, v| link_params[k] = v if k.start_with?('data-')}

    Link(target, link_params) do
      with_right_icon(right_icon.present?) do
        if text.present?
          DIV(class: 'd-flex flex-row justify-content-start align-items-center') do
            I(class: "ib-icon ib-icon-left pr-2 fa fa-#{icon} fa-#{icon_size} fa-fw")
            SPAN(class: "ib-text #{is_flex ? 'd-none d-lg-flex' : ''} ") do
              text
            end
          end
        else
          I(class: "ib-icon ib-icon-left fa fa-#{icon} fa-#{icon_size} fa-fw")
        end
      end
    end.on(:click) do |event|
      click!(event)
    end
  end
end
