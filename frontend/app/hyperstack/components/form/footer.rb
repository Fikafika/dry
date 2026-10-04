class Form::Footer < HyperComponent

  collect_other_params_as :other_params
  param :show_submit_button_from_page_number, default: nil

  render{ form ? content : DIV() {} }

  before_mount do
    observe form if form
  end

  before_update do
    observe form if form
  end

  def form
    ::Form.current
  end

  def content
    return unless form&.data_loaded?
    if form.navigation_count == 0
      Form::Element::Control::Navigation(form: form, timestamp: timestamp, buttons_automatically_shown: true, show_submit_button_from_page_number: show_submit_button_from_page_number) do
        render_children
      end
    else
      render_children
    end
  end

  def timestamp
    other_params[:timestamp] || next_timestamp
  end

  def render_children
    children.each do |c|
      if child_has_param?(c, "form")
        if child_has_param?(c, "current")
          c.render(form: form, current: form.submission.page)
        else
          c.render(form: form)
        end
      else
        c.render
      end
    end
  end

  def child_has_param?(c, para)
    return false unless `#{c.to_n}.props`
    `#{c.to_n}.props.hasOwnProperty(#{para})`
  end

  def next_timestamp
    @timestamp ||= 0
    @timestamp += 1
  end

end
